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
    
    // Canonical point cloud state (PCL)
    pcl::PointCloud<pcl::PointXYZRGB>::Ptr pcl_cloud;
    const float voxel_size = 0.05f; // 5 cm
    std::unordered_map<VoxelKey, VoxelData, 
        VoxelKeyHasher> voxel_map;

    pcl_stream_voxel_filter() {
        pcl_cloud.reset(new pcl::PointCloud<pcl::PointXYZRGB>);        
    }

    void consume_point_cloud_chunk(uint8_t *buf, ssize_t bytes) {
        std::string_view chunk((const char *)buf, bytes);
        size_t start = 0;
        while (start < chunk.size()) {
            size_t end = chunk.find('\n', start);
            // skip incomplete trailing line
            if (end == std::string_view::npos) break;
            std::string_view line =
                chunk.substr(start, end - start);
            start = end + 1;
            float x, y, z;
            float r, g, b;
            if (sscanf(
                std::string(line).c_str(),
                "%f %f %f %f %f %f",
                &x, &y, &z,
                &r, &g, &b) != 6) {
                continue;
            }
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
                voxel.sr = r;
                voxel.sg = g;
                voxel.sb = b;
                voxel.count = 1;
                voxel.changed = true;
                pcl::PointXYZRGB p;
                p.x = x;
                p.y = y;
                p.z = z;
                p.r = static_cast<uint8_t>(r);
                p.g = static_cast<uint8_t>(g);
                p.b = static_cast<uint8_t>(b);
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
                voxel.sr += r;
                voxel.sg += g;
                voxel.sb += b;
                voxel.count++;
                float inv = 1.0f / voxel.count;
                auto& p = pcl_cloud->points[voxel.point_index];
                p.x = voxel.sx * inv;
                p.y = voxel.sy * inv;
                p.z = voxel.sz * inv;
                p.r = static_cast<uint8_t>(
                        voxel.sr * inv);
                p.g = static_cast<uint8_t>(
                        voxel.sg * inv);
                p.b = static_cast<uint8_t>(
                        voxel.sb * inv);                    
            }
        }
    }
};

#endif