#ifndef ORIENTATION_H
#define ORIENTATION_H

#include <cmath>
#include <cstdint>
#include <numbers>

namespace imu {

struct sample {
    uint64_t ts_ms;
    double ax, ay, az;
    double gx, gy, gz;
    double mx, my, mz;
};

struct quaternion {

    double w = 1.0;
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;

    quaternion operator *(const quaternion& q) const {
        return {
            w*q.w - x*q.x - y*q.y - z*q.z,
            w*q.x + x*q.w + y*q.z - z*q.y,
            w*q.y - x*q.z + y*q.w + z*q.x,
            w*q.z + x*q.y - y*q.x + z*q.w
        };
    }

    void normalize() {
        double n = std::sqrt
            (w*w + x*x + y*y + z*z);
        if (n < 1e-12) {
            w = 1.0;
            x = y = z = 0.0;
            return;
        }
        w /= n;
        x /= n;
        y /= n;
        z /= n;
    }
};

struct orientation {

    orientation() { reset(); }
    
    const quaternion& get_quaternion() const { return q_; }
    
    void reset() {
        q_ = {1.0, 0.0, 0.0, 0.0};
        has_prev_ = false;
        prev_ts_ms_ = 0;
    }

    void update(const sample& sample) {
        if (!has_prev_) {
            prev_ts_ms_ = sample.ts_ms;
            has_prev_ = true;
            return;
        }
        double dt = (sample.ts_ms - prev_ts_ms_) * 0.001;
        prev_ts_ms_ = sample.ts_ms;
        if (dt <= 0.0) return;
        constexpr double DEG2RAD = std::numbers::pi / 180.0;
        double gx = sample.gx * DEG2RAD;
        double gy = sample.gy * DEG2RAD;
        double gz = sample.gz * DEG2RAD;        
        // Rotation vector
        double rx = gx * dt;
        double ry = gy * dt;
        double rz = gz * dt;
        // Magnitude
        double angle = std::sqrt(rx*rx + ry*ry + rz*rz);
        if (angle < 1e-12) return;
        // Unit axis
        double ax = rx / angle;
        double ay = ry / angle;
        double az = rz / angle;
        // Incremental quaternion
        auto dq = axisAngleToQuaternion(ax, ay, az, angle);
        // Integrate
        q_ = q_ * dq;
        q_.normalize();
    }

    quaternion axisAngleToQuaternion(
        double ax, double ay, double az, double angle) {
        double half = angle * 0.5;
        double s = std::sin(half);
        return {
            std::cos(half),
            ax * s,
            ay * s,
            az * s
        };
    }

    quaternion q_;
    bool has_prev_ = false;
    uint64_t prev_ts_ms_ = 0;
};

} //namespace imu

#endif