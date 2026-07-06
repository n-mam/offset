#ifndef IMU_H
#define IMU_H

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

struct vec3 { double x, y, z; };

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
        double inv = 1.0 / n;
        w *= inv;
        x *= inv;
        y *= inv;
        z *= inv;
    }
};

struct orientation {

    orientation() { reset(); }
    
    const quaternion& get_quaternion() const { return q_; }
    
    void reset() {
        // Identity body->world rotation.
        // Initially, the body and world frames are aligned.
        q_ = {1.0, 0.0, 0.0, 0.0};
        has_prev_ = false;
        prev_ts_ms_ = 0;
    }
    // Mahony's proportional observer
    // using current q_
    // predict gravity
    // Rotation error = measured × predicted (g)
    // correct the gyro using this error
    // update estimate
    void update(const sample& s) {
        if (!has_prev_) {
            prev_ts_ms_ = s.ts_ms;
            has_prev_ = true;
            return;
        }
        if (s.ts_ms <= prev_ts_ms_) return;        
        double dt = (s.ts_ms - prev_ts_ms_) * 0.001;
        prev_ts_ms_ = s.ts_ms;
        constexpr double DEG2RAD = std::numbers::pi / 180.0;
        // Gyroscope 
        double wx = s.gx * DEG2RAD;
        double wy = s.gy * DEG2RAD;
        double wz = s.gz * DEG2RAD;
        // Accelerometer
        double ax = s.ax;
        double ay = s.ay;
        double az = s.az;
        double norm = std::sqrt(ax * ax + ay * ay + az * az);
        if (norm < 1e-3) return;
        if (std::abs(norm - 1.0) > 0.15) return;
        double inv = 1.0 / norm;
        ax *= inv; 
        ay *= inv; 
        az *= inv;
        // Predicted gravity in body frame from current attitude estimate
        // q_ transforms body -> world, therefore
        // gravity(body) = inv(q_) * gravity(world) * q_
        vec3 g_w = {0, 0, 1};
        vec3 g_b = transformWorldToBody(q_, g_w);
        double gx = g_b.x;
        double gy = g_b.y;
        double gz = g_b.z;
        // Mahony proportional error
        double ex = ay * gz - az * gy;
        double ey = az * gx - ax * gz;
        double ez = ax * gy - ay * gx;
        // Correction
        constexpr double kp = 0.05;
        wx += kp * ex;
        wy += kp * ey;
        wz += kp * ez;
        // Rotation vector (angular velocity integrated over dt)
        double rx = wx * dt;
        double ry = wy * dt;
        double rz = wz * dt;
        quaternion dq;
        // Exponential map: rotation vector -> incremental quaternion
        double theta = std::sqrt(rx * rx + ry * ry + rz * rz);
        if (theta < 1e-6) {
            // first order approximation 
            // using taylor expansion
            dq.w = 1.0;
            dq.x = 0.5 * rx;
            dq.y = 0.5 * ry;
            dq.z = 0.5 * rz;            
        } else {
            inv = 1.0 / theta;
            double ux = rx * inv;
            double uy = ry * inv;
            double uz = rz * inv;
            dq = axisAngleToQuaternion(ux, uy, uz, theta);            
        }
        // Update orientation estimate
        // body-frame incremental rotation
        q_ = q_ * dq;
        q_.normalize();
        // next would be adding the gyro bias estimator (Ki)
        // followed by the accelerometer low-pass filter.
    }

    static vec3 transformWorldToBody(const quaternion& q, const vec3& v) {
        // Transform a vector from the world frame into the
        // body frame.q represents the body->world orientation.
        // Computes q⁻¹ * v * q.
        quaternion vq{0, v.x, v.y, v.z};
        quaternion q_conjugate{q.w, -q.x, -q.y, -q.z};
        quaternion rq = q_conjugate * vq * q;
        return {rq.x, rq.y, rq.z};
    }

    static quaternion axisAngleToQuaternion(
        double ux, double uy, double uz, double theta) {
        double half = theta * 0.5;
        double s = std::sin(half);
        return {
            std::cos(half),
            ux * s,
            uy * s,
            uz * s
        };
    }

    quaternion q_;
    bool has_prev_ = false;
    uint64_t prev_ts_ms_ = 0;
};

} //namespace imu

#endif