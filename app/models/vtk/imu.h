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
        // initial "no rotation" identity quaternion
        // This is a body -> world transformer both 
        // of which are align initially
        q_ = {1.0, 0.0, 0.0, 0.0};
        has_prev_ = false;
        prev_ts_ms_ = 0;
    }

    // Mahony's proportional observer
    // current q_
    // predict gravity
    // compute error
    // correct gyro
    // single quaternion integration
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
        // Gyroscope (rad/s)
        double gx = sample.gx * DEG2RAD;
        double gy = sample.gy * DEG2RAD;
        double gz = sample.gz * DEG2RAD;
        // Accelerometer
        double a_x = sample.ax;
        double a_y = sample.ay;
        double a_z = sample.az;
        double norm = std::sqrt(a_x * a_x + a_y * a_y + a_z * a_z);
        if (norm < 1e-6) return;
        a_x /= norm;
        a_y /= norm;
        a_z /= norm;
        // Predicted gravity in body frame from current attitude estimate
        // q_ transforms body -> world
        // Therefore gravity(body) = inv(q_) * gravity(world) * q_
        double g_x = 2.0 * (q_.x * q_.z - q_.w * q_.y);
        double g_y = 2.0 * (q_.w * q_.x + q_.y * q_.z);
        double g_z = q_.w * q_.w - q_.x * q_.x - q_.y * q_.y + q_.z * q_.z;
        // Mahony proportional error
        double ex = a_y * g_z - a_z * g_y;
        double ey = a_z * g_x - a_x * g_z;
        double ez = a_x * g_y - a_y * g_x;
        // Correction
        constexpr double kp = 0.05;
        gx += kp * ex;
        gy += kp * ey;
        gz += kp * ez;
        // Integrate corrected angular velocity (ONE integration only)
        double rx = gx * dt;
        double ry = gy * dt;
        double rz = gz * dt;
        double angle = std::sqrt(rx * rx + ry * ry + rz * rz);
        if (angle > 1e-12) {
            double ax = rx / angle;
            double ay = ry / angle;
            double az = rz / angle;
            auto dq = axisAngleToQuaternion(ax, ay, az, angle);
            // body-frame incremental rotation
            q_ = q_ * dq;
            q_.normalize();
        }
        // next would be adding the gyro bias estimator (Ki)
        // followed by the accelerometer low-pass filter.
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