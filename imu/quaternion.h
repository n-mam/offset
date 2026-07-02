#ifndef QUAT_H
#define QUAT_H

#include <cmath>

struct quatternion {

    double w = 1.0;
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;

    quatternion operator *(const quatternion& q) const {
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

#endif