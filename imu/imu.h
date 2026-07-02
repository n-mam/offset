#ifndef IMU_H
#define IMU_H

struct imu_sample {
    double gx;
    double gy;
    double gz;
    double dt;
};

struct imu {
    virtual ~imu() = default;
    virtual bool poll(imu_sample& sample) = 0;
};

#endif