#ifndef SIM_H
#define SIM_H

#include <imu.h>

#include <cmath>
#include <chrono>
#include <numbers>

struct sim_imu : public imu {

    explicit sim_imu(double gz_dps) {
        _gx = 0.0; 
        _gy = 0.0;
        _gz = gz_dps * (std::numbers::pi / 180);
        _last = std::chrono::steady_clock::now();
    }

    virtual ~sim_imu() = default;

    void set_angular_velocity(double gx_dps, double gy_dps, double gz_dps) {
        _gx = gx_dps * (std::numbers::pi / 180);
        _gy = gy_dps * (std::numbers::pi / 180);
        _gz = gz_dps * (std::numbers::pi / 180);
    }

    bool poll(imu_sample& sample) override {
        auto now = std::chrono::steady_clock::now();
        auto dt = now - _last;
        _last = now;
        sample.dt = std::chrono::duration<double>(dt).count();
        sample.gx = _gx;
        sample.gy = _gy;
        sample.gz = _gz;
        return true;
    }

    private:

    double _gx, _gy, _gz;

    std::chrono::steady_clock::time_point _last;
};

#endif