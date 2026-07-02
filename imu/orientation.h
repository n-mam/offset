#ifndef ORIENTATION_H
#define ORIENTATION_H

#include <imu.h>
#include <quaternion.h>

#include <cmath>

struct orientation {

    quatternion q_;

    orientation() {
        reset();
    }

    void update(const imu_sample& sample) {
        // Rotation vector
        double rx = sample.gx * sample.dt;
        double ry = sample.gy * sample.dt;
        double rz = sample.gz * sample.dt;
        // Magnitude
        double angle = 
            std::sqrt(rx*rx + ry*ry + rz*rz);
        if (angle < 1e-12) return;
        // Unit axis
        double ax = rx / angle;
        double ay = ry / angle;
        double az = rz / angle;
        // Incremental quatternion
        auto dq = axisAngleToQuaternion
            (ax, ay, az, angle);
        // Integrate
        q_ = q_ * dq;
        q_.normalize();
    }

    void reset() {
        q_.w = 1.0;
        q_.x = 0.0;
        q_.y = 0.0;
        q_.z = 0.0;
    }

    const quatternion& get_quaternion() const {
        return q_;
    }

    quatternion axisAngleToQuaternion(
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
};

#endif