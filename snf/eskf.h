#ifndef IMU_ESKF_DIFFABLE_H
#define IMU_ESKF_DIFFABLE_H

#include <cmath>
#include <cstdint>
#include <variant>
#include <numbers>

#include <snf/snf.h>

namespace snf {

struct eskf {

    eskf() { reset(); }

    const quaternion& get_quaternion() const { return q_; }

    void reset() {
        prev_ts_ms_ = 0;
        has_prev_ = false;
        q_ = {1.0, 0.0, 0.0, 0.0};
        gyro_bias_ = {0, 0, 0};
        // Pqq/Pqb/Pbb are the covariance carried by the ESKF
        // They describe uncertainty in the *local error state*
        // [delta_theta, delta_bias], not the actual quaternion/bias values
        // (q_, gyro_bias_) themselves; essence of an error-state KF.
        Pqq = mat3::identity().scaled(1e-2);   // ~5.7 deg (1-sigma) initial orientation uncertainty
        Pqb = mat3{};                          // orientation<->bias correlation (starts uncorrelated)
        // Set relative to expected RESIDUAL bias after your firmware
        // calibrate() step, not the raw sensor spec -- 1e-5 corresponds to
        // ~0.003 rad/s (~0.18 deg/s) 1-sigma. If startup calibration leaves
        // more residual than that, this should be larger, or the filter
        // starts overconfident and is slow to correct gyro_bias_.
        Pbb = mat3::identity().scaled(1e-5);
    }

    void update(const sample& s) {
        if (!has_prev_) { prev_ts_ms_ = s.ts_ms; has_prev_ = true; return; }
        if (s.ts_ms <= prev_ts_ms_) return;
        double dt = (s.ts_ms - prev_ts_ms_) * 0.001;
        prev_ts_ms_ = s.ts_ms;
        // guard against timestamp glitches (dropped samples, clock jumps)
        // an unbounded dt would blow up the covariance propagation below
        if (dt <= 0.0 || dt > 0.1) return;
        constexpr double DEG2RAD = std::numbers::pi / 180.0;
        // gyroscope
        double wx = s.gx * DEG2RAD - gyro_bias_.x;
        double wy = s.gy * DEG2RAD - gyro_bias_.y;
        double wz = s.gz * DEG2RAD - gyro_bias_.z;
        vec3 omega = {wx, wy, wz};
        // PREDICT -- propagate quaternion AND covariance from gyro alone.
        {
            vec3 rv = {omega.x*dt, omega.y*dt, omega.z*dt};
            double angle = std::sqrt(rv.x*rv.x + rv.y*rv.y + rv.z*rv.z);
            quaternion dq;
            if (angle > 1e-12) {
                double half = 0.5*angle;
                double k = std::sin(half) / angle;
                dq = {std::cos(half), rv.x*k, rv.y*k, rv.z*k};
            } else {
                dq = {1.0, 0.5*rv.x, 0.5*rv.y, 0.5*rv.z};
            }
            q_ = q_ * dq;
            q_.normalize();

            // Phi = I + F*dt, F = [-skew(omega) -I; 0 0]  (see the reference derivation)
            mat3 I = mat3::identity();
            mat3 Wx = mat3::skew(omega);
            mat3 Phi_qq = I - Wx.scaled(dt);
            mat3 Phi_qb = I.scaled(-dt);

            mat3 newPqq = Phi_qq * Pqq * Phi_qq.transpose()
                        + Phi_qq * Pqb * Phi_qb.transpose()
                        + Phi_qb * Pqb.transpose() * Phi_qq.transpose()
                        + Phi_qb * Pbb * Phi_qb.transpose()
                        + Q_theta_.scaled(dt);

            mat3 newPqb = Phi_qq * Pqb + Phi_qb * Pbb;
            mat3 newPbb = Pbb + Q_bias.scaled(dt);

            Pqq = newPqq;
            Pqb = newPqb;
            Pbb = newPbb;
        }
        // accelerometer
        // ESKF: residual is a plain vector subtraction instead, and the
        // gain is computed from Pqq/Pqb instead of being kp_acc/ki_acc.
        vec3 a = {s.ax, s.ay, s.az};
        bool acc_valid = a.normalize() && (std::abs(a.n - 1.0) <= 0.15);
        if (acc_valid) {
            vec3 gw = {0, 0, 1};
            vec3 a_pred = transform_world_to_body(q_, gw);
            vec3 r = a - a_pred; // MAHONY's e_a = a x gb
            mat3 H = mat3::skew(a_pred).scaled(-1.0);
            correct(H, r, R_acc);
        }
        // magnetometer -- identical yaw-only trick as in Mahony (m_ref built
        // with azimuth zeroed out), just corrected via the same computed
        // gain machinery instead of kp_mag/ki_mag.
        double tx = s.mx, ty = s.my;
        vec3 m = {-ty, tx, s.mz};   // same HMC->MPU axis remap as Mahony
        bool mag_valid = m.normalize();
        if (acc_valid && mag_valid) {
            vec3 mw = transform_body_to_world(q_, m);
            double bxy = std::sqrt(mw.x*mw.x + mw.y*mw.y);
            if (bxy > 1e-6) {
                vec3 m_ref = {bxy, 0.0, mw.z};
                m_ref.normalize();
                vec3 m_pred = transform_world_to_body(q_, m_ref);
                vec3 r = m - m_pred; // MAHONY's e_m = m x m_pred
                mat3 H = mat3::skew(m_pred).scaled(-1.0);
                correct(H, r, R_mag);
            }
        }
    }

    void control_imu(const std::string& key,
            const std::variant<bool, double>& value)
    {

    }

    private:

    // compute a gain from (Pqq, Pqb, H, R) instead
    // of using a fixed kp/ki, then apply it.
    void correct(const mat3& H, const vec3& r, const mat3& R) {
        mat3 Ht = H.transpose();
        mat3 S = H * Pqq * Ht + R;
        mat3 Sinv;
        if (!S.invert(Sinv)) return;

        mat3 K_theta = Pqq * Ht * Sinv;         // MAHONY's kp_acc
        mat3 K_bias  = Pqb.transpose() * Ht * Sinv; // MAHONY's ki_acc

        vec3 dtheta = K_theta * r;
        vec3 dbias  = K_bias * r;

        // fold into nominal state -- MAHONY did the analogous thing via
        // "wx += kp_acc*e_ax + gyro_bias_.x" feeding the rate integration;
        // here it's a direct multiplicative quaternion correction instead.
        quaternion dq = {1.0, 0.5 * dtheta.x, 0.5 * dtheta.y, 0.5 * dtheta.z};
        q_ = q_ * dq;
        q_.normalize();
        gyro_bias_.x += dbias.x;
        gyro_bias_.y += dbias.y;
        gyro_bias_.z += dbias.z;
        // shrink P: the measurement just reduced our uncertainty about the
        // error state, so P is updated to reflect what's left
        mat3 I = mat3::identity();
        mat3 KH = K_theta * H;
        mat3 ImKH = I - KH;
        mat3 newPqq = ImKH * Pqq * ImKH.transpose() + K_theta * R * K_theta.transpose();
        // Algebraically equivalent to (and simplifies from) the block-Joseph
        // expansion, using K_theta = Pqq*Ht*Sinv and S = H*Pqq*Ht + R --
        // the correction terms cancel.
        mat3 newPqb = ImKH * Pqb;
        // "A measurement reduced our uncertainty about the gyro bias."
        // Simplifies from the block-Joseph form using K_bias = Pqb^T*Ht*Sinv.
        mat3 newPbb = Pbb - K_bias * S * K_bias.transpose();
        Pqq = newPqq;
        Pqb = newPqb;
        Pbb = newPbb;
    }

    quaternion q_;
    bool has_prev_ = false;
    uint64_t prev_ts_ms_ = 0;
    vec3 gyro_bias_ = {0, 0, 0};

    mat3 Pqq, Pqb, Pbb;
    mat3 Q_theta_ = mat3::identity().scaled(1e-4);
    mat3 Q_bias  = mat3::identity().scaled(1e-8);
    mat3 R_acc   = mat3::identity().scaled(3e-2);
    mat3 R_mag   = mat3::identity().scaled(5e-2);
};

} // namespace

#endif