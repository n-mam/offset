#ifndef VOXEL
#define VOXEL

#include <tuple>
#include <cmath>
#include <fstream>
#include <iostream>
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
    uint32_t count = 0;
    uint32_t point_index = 0;
    bool changed = false;
};

struct VoxelKey {
    int x, y, z;
    bool operator==(const VoxelKey& other) const {
        return x == other.x &&
               y == other.y &&
               z == other.z;
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
    pcl::PointCloud<pcl::PointXYZ>::Ptr pcl_cloud;
    std::unordered_map<VoxelKey, VoxelData,
        VoxelKeyHasher> voxel_map;

    pcl_stream_voxel_filter() {
        voxel_map.reserve(1000000);
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

    void consume_point_cloud_chunk(uint8_t *buf, ssize_t bytes) {
        std::string_view chunk((const char *)buf, bytes);
        bool first_line_skipped = false;
        size_t start = 0;
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
            auto [has_xyz, has_rgb] =
                parse_xyz_rgb(line.data(),
                            line.data() + line.size(),
                            x, y, z, r, g, b);
            if (!has_xyz) continue;
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
            int vx = static_cast<int>(
                    std::floor(x / voxel_size));
            int vy = static_cast<int>(
                    std::floor(y / voxel_size));
            int vz = static_cast<int>(
                    std::floor(z / voxel_size));
            VoxelKey key{vx, vy, vz};
            auto it = voxel_map.find(key);
            // new voxel
            if (it == voxel_map.end()) {
                VoxelData voxel;
                voxel.sx = x;
                voxel.sy = y;
                voxel.sz = z;
                voxel.count = 1;
                voxel.changed = true;
                if (has_rgb) {
                    voxel.sr = r;
                    voxel.sg = g;
                    voxel.sb = b;
                } else {
                    voxel.sr = 255;
                    voxel.sg = 255;
                    voxel.sb = 255;
                }
                pcl::PointXYZ p;
                p.x = x;
                p.y = y;
                p.z = z;
                voxel.point_index =
                    static_cast<uint32_t>(
                        pcl_cloud->size());
                pcl_cloud->push_back(p);
                voxel_map[key] = voxel;
            } else {
                auto& voxel = it->second;
                voxel.changed = true;
                voxel.sx += x;
                voxel.sy += y;
                voxel.sz += z;
                voxel.count++;
                // Average RGB if new point has it
                if (has_rgb) {
                    voxel.sr = static_cast<uint8_t>((voxel.sr * (voxel.count - 1) + r) / voxel.count);
                    voxel.sg = static_cast<uint8_t>((voxel.sg * (voxel.count - 1) + g) / voxel.count);
                    voxel.sb = static_cast<uint8_t>((voxel.sb * (voxel.count - 1) + b) / voxel.count);
                }
                float inv = 1.0f / voxel.count;
                auto& p = pcl_cloud->points[voxel.point_index];
                p.x = voxel.sx * inv;
                p.y = voxel.sy * inv;
                p.z = voxel.sz * inv;
            }
        }
    }
};

#endif