#ifndef VOXEL
#define VOXEL

#include <tuple>
#include <cmath>
#include <limits>
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
    bool dirty;
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

struct stream_voxel_filter {

    std::string leftover;
    bool recentered = false;
    double min_x, min_y, min_z;
    double max_x, max_y, max_z;
    const float voxel_size = 0.5f;
    std::vector<VoxelKey> dirty_voxels;
    double origin_x, origin_y, origin_z;
    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud;
    std::unordered_map<VoxelKey, VoxelData, VoxelKeyHasher> voxel_map;

    stream_voxel_filter() {
        voxel_map.reserve(3*1024*1024); // * 5 for 0.1 voxel size
        dirty_voxels.reserve(500*1024); // based on 2MB chunks
        cloud.reset(new pcl::PointCloud<pcl::PointXYZ>);
        cloud->points.reserve(3*1024*1024); // * 5 for 0.1 voxel size
        min_x = min_y = min_z = std::numeric_limits<double>::infinity();
        max_x = max_y = max_z = -std::numeric_limits<double>::infinity();
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

    auto parse_cloud_chunk(uint8_t *buf, ssize_t bytes, 
            std::vector<ParsedPoint>& parsed_points) {
        parsed_points.clear();
        uint64_t points = 0;
        std::string_view chunk((const char*)buf, bytes);
        // Prepend leftover from previous chunk
        std::string combined;
        if (!leftover.empty()) {
            combined = leftover;
            combined.append(chunk);
            chunk = combined;
            leftover.clear();
        }
        size_t start = 0;
        while (start < chunk.size()) {
            size_t end = chunk.find('\n', start);
            bool last_line = false;
            if (end == std::string_view::npos) {
                // last line is incomplete, save it for next chunk
                leftover = std::string(chunk.substr(start));
                break;
            }
            std::string_view line = chunk.substr(start, end - start);
            start = end + 1;
            // handle CRLF
            if (!line.empty() && line.back() == '\r')
                line.remove_suffix(1);
            // skip empty/comment lines
            if (line.empty() || line.front() == '#')
                continue;
            double x, y, z;
            int r = 255, g = 255, b = 255;
            auto [has_xyz, has_rgb] =
                parse_xyz_rgb(line.data(), line.data() + line.size(),
                            x, y, z, r, g, b);
            if (!has_xyz) continue;
            ++points;
            if (!recentered) {
                origin_x = x;
                origin_y = y;
                origin_z = z;
                recentered = true;
            }
            x -= origin_x;
            y -= origin_y;
            z -= origin_z;
            min_x = std::min(min_x, x);
            min_y = std::min(min_y, y);
            min_z = std::min(min_z, z);
            max_x = std::max(max_x, x);
            max_y = std::max(max_y, y);
            max_z = std::max(max_z, z);            
            const double inv_voxel = 1.0 / voxel_size;
            int vx = static_cast<int>(std::floor(x * inv_voxel));
            int vy = static_cast<int>(std::floor(y * inv_voxel));
            int vz = static_cast<int>(std::floor(z * inv_voxel));
            parsed_points.emplace_back(x, y, z, r, g, b, vx, vy, vz);
        }
        return;
    }

    auto consume_cloud_chunk(uint8_t *buf, ssize_t bytes, 
            std::vector<ParsedPoint>& parsed_points, std::mutex& mux) {
        uint64_t new_voxels = 0;
        parse_cloud_chunk(buf, bytes, parsed_points);
        std::lock_guard<std::mutex> lg(mux);
        for (const auto& pp : parsed_points) {
            VoxelKey key{pp.vx, pp.vy, pp.vz};
            auto [it, inserted] = voxel_map.try_emplace(key);
            auto& voxel = it->second;
            if (inserted) {
                // new voxel
                ++new_voxels;
                voxel.count = 1;
                voxel.sx = pp.x;
                voxel.sy = pp.y;
                voxel.sz = pp.z;
                voxel.sr = pp.r;
                voxel.sg = pp.g;
                voxel.sb = pp.b;
                pcl::PointXYZ p;
                p.x = pp.x;
                p.y = pp.y;
                p.z = pp.z;
                voxel.point_index = static_cast
                    <uint32_t>(cloud->size());
                voxel.dirty = true;
                cloud->push_back(p);
                dirty_voxels.push_back(key);
            } else {
                voxel.count++;
                voxel.sx += pp.x;
                voxel.sy += pp.y;
                voxel.sz += pp.z;
                // average RGB
                voxel.sr += pp.r;
                voxel.sg += pp.g;
                voxel.sb += pp.b;
                double inv = 1.0 / voxel.count;
                auto& p = cloud->points[voxel.point_index];
                p.x = voxel.sx * inv;
                p.y = voxel.sy * inv;
                p.z = voxel.sz * inv;
                if (!voxel.dirty) {
                    voxel.dirty = true;
                    dirty_voxels.push_back(key);
                }
            }
        }
        return new_voxels;
    }
};

#endif