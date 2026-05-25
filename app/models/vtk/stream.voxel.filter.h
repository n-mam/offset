#ifndef VOXEL
#define VOXEL

#include <tuple>
#include <cmath>
#include <fstream>
#include <iostream>
#include <unordered_set>
#include <unordered_map>

#include <npl/npl>

#include <pcl/point_types.h>
#include <pcl/point_cloud.h>
#include <pcl/io/pcd_io.h>

struct VoxelData {
    double sx = 0;
    double sy = 0;
    double sz = 0;
    double sr = 0;
    double sg = 0;
    double sb = 0;
    bool dirty = false;
    uint32_t count = 0;
    uint32_t point_index = 0;
};

struct ParsedPoint {
    double x, y, z;
    int r, g, b;
    int vx, vy, vz;
};

struct VoxelKey {
    int x, y, z;
    bool operator==(const VoxelKey& k) const {
        return x == k.x && y == k.y && z == k.z;
    }
};

struct VoxelKeyHasher {
    std::size_t operator()(const VoxelKey& k) const {
        return ((std::hash<int>()(k.x) ^
                (std::hash<int>()(k.y) << 1)) >> 1) ^
                (std::hash<int>()(k.z) << 1);
    }
};

struct pcl_stream_voxel_filter {

    bool recentered = false;
    const float voxel_size = 1.0f;
    double origin_x, origin_y, origin_z;
    std::vector<VoxelKey> dirty_voxels;
    std::vector<ParsedPoint> parsed_points;
    pcl::PointCloud<pcl::PointXYZ>::Ptr pcl_cloud;
    std::unordered_map<VoxelKey, VoxelData, VoxelKeyHasher> voxel_map;

    pcl_stream_voxel_filter() {
        voxel_map.reserve(24*1024*1024);
        dirty_voxels.reserve(16*1024*1024);
        parsed_points.reserve(4*1024*1024);
        pcl_cloud.reset(new pcl::PointCloud<pcl::PointXYZ>);
    }

    inline std::pair<bool, bool>
    parse_xyz_rgb(const char* p, const char* end,
        double& x, double& y, double& z, int& r, int& g, int& b) {

        auto parse_double = [&](double& out) -> const char* {
            bool neg = false;
            if (*p == '-') { neg = true; ++p; }
            double val = 0.0;
            while (p < end && *p >= '0' && *p <= '9') {
                val = val * 10.0 + (*p - '0');
                ++p;
            }
            if (p < end && *p == '.') {
                ++p;
                double frac = 0.0, div = 1.0;
                while (p < end && *p >= '0' && *p <= '9') {
                    frac = frac * 10.0 + (*p - '0');
                    div *= 10.0;
                    ++p;
                }
                val += frac / div;
            }
            out = neg ? -val : val;
            return p;
        };
        auto parse_int = [&](int& out) -> const char* {
            int val = 0;
            while (p < end && *p >= '0' && *p <= '9') {
                val = val * 10 + (*p - '0');
                ++p;
            }
            out = val;
            return p;
        };

        // XYZ
        p = parse_double(x);
        if (p >= end || *p != ',') return {false, false};
        ++p;
        p = parse_double(y);
        if (p >= end || *p != ',') return {false, false};
        ++p;
        p = parse_double(z);

        bool has_xyz = true;
        bool has_rgb = false;

        // RGB
        if (p < end && *p == ',') {
            ++p;
            if (p >= end) return {has_xyz, false};
            p = parse_int(r);
            if (p >= end || *p != ',') return {has_xyz, false};
            ++p;
            p = parse_int(g);
            if (p >= end || *p != ',') return {has_xyz, false};
            ++p;
            p = parse_int(b);
            has_rgb = true;
        }
        return {has_xyz, has_rgb};
    }

    auto parse_cloud_chunk(uint8_t *buf, ssize_t bytes) {
        parsed_points.clear();
        size_t start = 0;
        uint64_t points = 0;
        bool first_line_skipped = false;
        std::string_view chunk((const char *)buf, bytes);
        while (start < chunk.size()) {
            size_t end = chunk.find('\n', start);
            // skip incomplete trailing line. This is fine
            if (end == std::string_view::npos) break;
            std::string_view line = chunk.substr(start, end - start);
            start = end + 1;
            // handle CRLF
            if (!line.empty() && line.back() == '\r')
                line.remove_suffix(1);
            // unconditionally skip first line. This is fine
            if (!first_line_skipped) {
                first_line_skipped = true;
                continue;
            }
            // skip empty/comment lines
            if (line.empty() || line.front() == '#') continue;
            double x, y, z;
            int r, g, b;
            r = g = b = 255;
            auto [has_xyz, has_rgb] =
                parse_xyz_rgb(line.data(),
                            line.data() + line.size(),
                            x, y, z, r, g, b);
            if (!has_xyz) continue;
            ++points;
            // re-center relative to first point
            if (!recentered) {
                origin_x = x;
                origin_y = y;
                origin_z = z;
                recentered = true;
            }
            x -= origin_x;
            y -= origin_y;
            z -= origin_z;
            const double inv_voxel = 1.0 / voxel_size;
            int vx = static_cast<int>(
                    std::floor(x * inv_voxel));
            int vy = static_cast<int>(
                    std::floor(y * inv_voxel));
            int vz = static_cast<int>(
                    std::floor(z * inv_voxel));
            parsed_points.push_back({x, y, z, r, g, b, vx, vy, vz,});
        }
        return points;
    }

    auto consume_cloud_chunk(uint8_t *buf, ssize_t bytes, std::mutex& mux) {
        uint64_t voxels = 0;
        auto points = parse_cloud_chunk(buf, bytes);
        std::lock_guard<std::mutex> lg(mux);
        for (const auto& pp : parsed_points) {
            VoxelKey key{pp.vx, pp.vy, pp.vz};
            auto it = voxel_map.find(key);
            // new voxel
            if (it == voxel_map.end()) {
                ++voxels;
                VoxelData voxel;
                voxel.sx = pp.x;
                voxel.sy = pp.y;
                voxel.sz = pp.z;
                voxel.count = 1;
                voxel.sr = pp.r;
                voxel.sg = pp.g;
                voxel.sb = pp.b;
                pcl::PointXYZ p;
                p.x = pp.x;
                p.y = pp.y;
                p.z = pp.z;
                voxel.point_index = static_cast<uint32_t>(
                        pcl_cloud->size());
                pcl_cloud->push_back(p);
                auto [it, success] = voxel_map.emplace(key, voxel);
                if (!it->second.dirty) {
                    it->second.dirty = true;
                    dirty_voxels.push_back(key);
                }
            } else {
                auto& voxel = it->second;
                voxel.sx += pp.x;
                voxel.sy += pp.y;
                voxel.sz += pp.z;
                voxel.count++;
                // average RGB
                voxel.sr += pp.r;
                voxel.sg += pp.g;
                voxel.sb += pp.b;
                float inv = 1.0f / voxel.count;
                auto& p = pcl_cloud->points[voxel.point_index];
                p.x = voxel.sx * inv;
                p.y = voxel.sy * inv;
                p.z = voxel.sz * inv;
                if (!voxel.dirty) {
                    voxel.dirty = true;
                    dirty_voxels.push_back(key);
                }
            }
        }
        return std::make_pair(points, voxels);
    }
};

#endif