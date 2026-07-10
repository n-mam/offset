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

struct vec3 {
    double x, y, z;
    double n = 0;
    bool normalize() {
        n = std::sqrt(x*x + y*y + z*z);
        bool ret = n > 1e-6;
        if (ret) {
            double inv = 1.0 / n;
            x *= inv;
            y *= inv;
            z *= inv;
        }
        return ret;
    }
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
        if (n <= 1e-12) {
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
        m_ref = {0,0,0};
        prev_ts_ms_ = 0;
        has_prev_ = false;
        q_ = {1.0, 0.0, 0.0, 0.0};
    }

    // Mahony's proportional observer
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
        // gyroscope
        double wx = s.gx * DEG2RAD;
        double wy = s.gy * DEG2RAD;
        double wz = s.gz * DEG2RAD;
        // accelerometer
        vec3 a = {s.ax, s.ay, s.az};
        bool acc_valid = a.normalize() &&
            (std::abs(a.n - 1.0) <= 0.15);
        // acc proportional error a(measured) x g(body)
        double e_ax = 0.0, e_ay = 0.0, e_az = 0.0;
        if (acc_valid) {
            // predicted gravity in body frame from the current attitude 
            // estimate. since q_ transforms body -> world, therefore
            // g(body) = inv(q_) * g(world) * q_
            vec3 gw = {0, 0, 1};
            vec3 gb = transform_world_to_body(q_, gw);
            e_ax = a.y * gb.z - a.z * gb.y;
            e_ay = a.z * gb.x - a.x * gb.z;
            e_az = a.x * gb.y - a.y * gb.x;
        }            
        // magnetometer
        // axis re-map depends on how we have mounted the discreete chips
        // Magnetometer (HMC) is mounted 90° CCW relative to the MPU6050.
        // HMC y is 90 deg ccw to MPU y 
        // HMC x is 90 deg ccw to MPU x 
        // Here I am using MPU as the primary ref frame and so mag values are changed accordingly
        // Rotate the magnetometer measurements into the MPU6050 reference frame.        
        double tx = s.mx;
        double ty = s.my;
        // s.mx = -ty; s.my = tx;
        // vec3 m = {s.mx, s.my, s.mz};
        vec3 m = {-ty, tx, s.mz};
        bool mag_valid = m.normalize();
        // mag proportional error m(measured) x m(reference)
        double e_mx = 0.0, e_my = 0.0, e_mz = 0.0;
        if (mag_valid) {
            if (!has_mag_ref_) {
                --sample_hold_count;
                if (sample_hold_count == 0) {
                    // measured magnetic field rotated into world frame
                    vec3 mw = transform_body_to_world(q_, m);
                    // horizontal field magnitude
                    double bx = std::sqrt(mw.x * mw.x + mw.y * mw.y);
                    // avoid singularity
                    if (bx > 1e-6) {
                        // reference magnetic field in world frame
                        m_ref = {bx, 0.0, mw.z};
                        m_ref.normalize();
                        has_mag_ref_ = true;
                    }
                }
            } else {
                // transform the fixed world mag ref into predicted reference
                // magnetic field in body frame using the current orientation
                vec3 m_pred = transform_world_to_body(q_, m_ref);
                // only take the component of the error about the body Z axis (yaw).
                // This is the z-component of the full cross product, but we deliberately
                // discard e_mx, e_my so mag can never correct roll/pitch.                
                e_mz = m.x * m_pred.y - m.y * m_pred.x;
            }
        }
        // correction
        constexpr double kp_acc = 0.05;
        constexpr double kp_mag = 0.05;
        wx += kp_acc * e_ax + kp_mag * e_mx;
        wy += kp_acc * e_ay + kp_mag * e_my;
        wz += kp_acc * e_az + kp_mag * e_mz;
        // rotation vector (angular velocity integrated over dt)
        quaternion dq;
        vec3 rv = {wx*dt, wy*dt, wz*dt};
        if (!rv.normalize()) {
            // first-order Taylor approximation of the quaternion
            // exponential for small rotation angles (theta->0)
            dq.w = 1.0;
            dq.x = 0.5 * rv.x;
            dq.y = 0.5 * rv.y;
            dq.z = 0.5 * rv.z;
        } else {
            // exponential map
            // rotation vector -> incremental quaternion
            dq = axisAngleToQuaternion(rv.x, rv.y, rv.z, rv.n);
        }
        // update orientation estimate
        // body-frame incremental rotation
        q_ = q_ * dq;
        q_.normalize();
        // gyro bias estimator (Ki) and accelerometer
        // low-pass filter are doen in firmware
    }

    static vec3 transform_world_to_body(const quaternion& q, const vec3& v) {
        // Transform a vector from the world frame into the
        // body frame. q represents the body->world orientation.
        // Computes q⁻¹ * v * q.
        quaternion vq{0, v.x, v.y, v.z};
        quaternion q_conjugate{q.w, -q.x, -q.y, -q.z};
        quaternion rq = q_conjugate * vq * q;
        return {rq.x, rq.y, rq.z};
    }

    static vec3 transform_body_to_world(const quaternion& q, const vec3& v) {
        // Transform a vector from the body frame into the
        // world frame. q represents the body->world orientation.
        // Computes q * v * q⁻¹.
        quaternion vq{0, v.x, v.y, v.z};
        quaternion q_conjugate{q.w, -q.x, -q.y, -q.z};
        quaternion rq = q * vq * q_conjugate;
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

    vec3 m_ref;
    quaternion q_;
    bool has_prev_ = false;
    uint64_t prev_ts_ms_ = 0;
    bool has_mag_ref_ = false;
    uint32_t sample_hold_count = 250;
};

} //namespace imu

#endif