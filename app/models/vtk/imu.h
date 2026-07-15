#ifndef IMU_H
#define IMU_H

#include <cmath>
#include <cstdint>
#include <numbers>
#include <variant>
#include <iostream>

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
        prev_ts_ms_ = 0;
        has_prev_ = false;
        // Identity body->world rotation. Initially the body and
        // world frames are aligned. This implies that the actual
        // world frame is the initial body frame; and that has no
        // relation to where the true magnetic north lies. Every
        // rotation from the "current" body frame using q_ rotates the
        // vector into this "initial" body frame(aka world frame) and
        // every rotation from the world frame (i.e. the initial body
        // frame) using q_ rotates the vector into the "current" body frame
        q_ = {1.0, 0.0, 0.0, 0.0};
    }

    // Mahony's proportional observer
    void update(const sample& s) {
        if (log_.load(std::memory_order_relaxed)) {
            std::cout << "s : "
                << s.gx << "," << s.gy << "," << s.gz << ","
                    << s.ax << "," << s.ay << "," << s.az << ","
                        << s.mx << "," << s.my << "," << s.mz << std::endl;
        }
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
        double e_ax = 0.0, e_ay = 0.0, e_az = 0.0;
        if (acc_valid) {
            // predicted gravity in body frame from the current attitude
            // estimate. since q_ transforms body -> world, therefore
            // g(body) = inv(q_) * g(world) * q_
            vec3 gw = {0, 0, 1};
            vec3 gb = transform_world_to_body(q_, gw);
            // acc proportional error
            // a(measured) x g(body)
            // discard the z term; gravity
            // does not contribute to yaw
            e_ax = a.y * gb.z - a.z * gb.y;
            e_ay = a.z * gb.x - a.x * gb.z;
            e_az = a.x * gb.y - a.y * gb.x;
        }
        // magnetometer
        // HMC y is 90 deg ccw to MPU y
        // HMC x is 90 deg ccw to MPU x
        // Here I am using MPU as the primary ref frame
        // and so mag values are changed accordingly
        double tx = s.mx;
        double ty = s.my;
        // s.mx = -ty; s.my = tx;
        // vec3 m = {s.mx, s.my, s.mz};
        vec3 m = {-ty, tx, s.mz};
        bool mag_valid = m.normalize();
        // mag proportional error m(measured) x m(reference)
        double e_mx = 0.0, e_my = 0.0, e_mz = 0.0;
        if (acc_valid && mag_valid) {
            // measured magnetic field rotated into world
            // frame using the current quaternion which
            // presumably is off by yaw error
            vec3 mw = transform_body_to_world(q_, m);
            // horizontal x-y plane field magnitude
            double bx = std::sqrt(mw.x * mw.x + mw.y * mw.y);
            // avoid singularity
            if (bx > 1e-6) {
                // construct reference magnetic field in the world frame.
                // this is NOT EQUAL to mw. It retains mw's magnitude
                // but discards the mw's yaw. "mw's yaw" is mw's proper
                // yaw + the induced yaw error due to rotating it with bad q_
                vec3 m_ref = {bx, 0.0, mw.z};
                m_ref.normalize();
                // transform the fixed world mag ref into predicted reference
                // magnetic field in body frame using the current orientation
                vec3 m_pred = transform_world_to_body(q_, m_ref);
                // Here, instead of transforming m_ref(world) to m_pred(body) we
                // could have also directly cross multiplied mw(world) with m_ref(world).
                // That would also have produced a perfectly valid rotation error vector.
                // But that error vector would have been in the world frame and we need to
                // apply corrections to angular velocities in the body frame. If we were to
                // use that method instead then the resulting world error vector would have
                // to be rotated back to body frame using _q. Both are mathematically equivalent.
                e_mx = m.y * m_pred.z - m.z * m_pred.y;
                e_my = m.z * m_pred.x - m.x * m_pred.z;
                e_mz = m.x * m_pred.y - m.y * m_pred.x;
            }
        }
        // load controller gains once per update
        const double kp_acc = _kp_acc.load(std::memory_order_relaxed);
        const double ki_acc = _ki_acc.load(std::memory_order_relaxed);
        const double kp_mag = _kp_mag.load(std::memory_order_relaxed);
        const double ki_mag = _ki_mag.load(std::memory_order_relaxed);
        // gyro bias integral term
        gyro_bias_.x += (ki_acc * e_ax + ki_mag * e_mx) * dt;
        gyro_bias_.y += (ki_acc * e_ay + ki_mag * e_my) * dt;
        gyro_bias_.z += (ki_acc * e_az + ki_mag * e_mz) * dt;
        // correction: proportional and integral
        wx += kp_acc * e_ax + kp_mag * e_mx + gyro_bias_.x;
        wy += kp_acc * e_ay + kp_mag * e_my + gyro_bias_.y;
        wz += kp_acc * e_az + kp_mag * e_mz + gyro_bias_.z;
        if (log_.load(std::memory_order_relaxed)) {
            std::cout << "e : "
                << "acc(" << e_ax << "," << e_ay << "," << e_az << ") "
                    << "mag(" << e_mx << "," << e_my << "," << e_mz << ") "
                        << "kp_acc=" << kp_acc << " " << "ki_acc=" << ki_acc << " "
                            << "kp_mag=" << kp_mag << " " << "ki_mag=" << ki_mag << " "
                                << "bias(" << gyro_bias_.x << "," << gyro_bias_.y << ","
                                    << gyro_bias_.z << ")" << std::endl;
        }
        // rotation vector (angular velocity integrated over dt)
        quaternion dq;
        vec3 rv = {wx*dt, wy*dt, wz*dt};
        if (rv.normalize()) {
            // exponential map
            // rotation vector -> incremental quaternion
            dq = axisAngleToQuaternion(rv.x, rv.y, rv.z, rv.n);
        } else {
            // first-order Taylor approximation of the quaternion
            // exponential for small rotation angles (theta->0)
            dq.w = 1.0;
            dq.x = 0.5 * rv.x;
            dq.y = 0.5 * rv.y;
            dq.z = 0.5 * rv.z;
        }
        // update orientation estimate
        // body-frame incremental rotation
        q_ = q_ * dq;
        q_.normalize();
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

    void control_imu(const std::string& key,
            const std::variant<bool, double>& value) {
        if (key == "log") {
            log_.store(std::get<bool>(value), std::memory_order_relaxed);
        } else if (key == "kp_acc") {
            _kp_acc.store(std::get<double>(value), std::memory_order_relaxed);
        } else if (key == "ki_acc") {
            _ki_acc.store(std::get<double>(value), std::memory_order_relaxed);
        } else if (key == "kp_mag") {
            _kp_mag.store(std::get<double>(value), std::memory_order_relaxed);
        } else if (key == "ki_mag") {
            _ki_mag.store(std::get<double>(value), std::memory_order_relaxed);
        }
    }

    quaternion q_;
    bool has_prev_ = false;
    uint64_t prev_ts_ms_ = 0;
    vec3 gyro_bias_ = {0, 0, 0};
    std::atomic_bool log_{false};
    std::atomic<double> _kp_acc{2.0};
    std::atomic<double> _ki_acc{0.01};
    std::atomic<double> _kp_mag{2.0};
    std::atomic<double> _ki_mag{0.01};
};

} //namespace imu

#endif