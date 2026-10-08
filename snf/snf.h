#ifndef SNF_H
#define SNF_H

#include <cmath>
#include <stdint.h>

namespace snf {

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
    vec3 operator -(const vec3& o) const {
        return {x - o.x, y - o.y, z - o.z};
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

struct mat3 {
    double m[3][3] = {};
    static mat3 identity() { mat3 r; r.m[0][0]=r.m[1][1]=r.m[2][2]=1; return r; }
    static mat3 skew(const vec3& v) {
        mat3 r;
        r.m[0][1]=-v.z; r.m[0][2]= v.y;
        r.m[1][0]= v.z; r.m[1][2]=-v.x;
        r.m[2][0]=-v.y; r.m[2][1]= v.x;
        return r;
    }
    mat3 transpose() const { mat3 r; for(int i=0;i<3;i++) for(int j=0;j<3;j++) r.m[j][i]=m[i][j]; return r; }
    mat3 operator*(const mat3& o) const {
        mat3 r;
        for (int i=0;i<3;i++) for (int j=0;j<3;j++) { double s=0; for(int k=0;k<3;k++) s+=m[i][k]*o.m[k][j]; r.m[i][j]=s; }
        return r;
    }
    mat3 operator+(const mat3& o) const { mat3 r; for(int i=0;i<3;i++) for(int j=0;j<3;j++) r.m[i][j]=m[i][j]+o.m[i][j]; return r; }
    mat3 operator-(const mat3& o) const { mat3 r; for(int i=0;i<3;i++) for(int j=0;j<3;j++) r.m[i][j]=m[i][j]-o.m[i][j]; return r; }
    mat3 scaled(double s) const { mat3 r; for(int i=0;i<3;i++) for(int j=0;j<3;j++) r.m[i][j]=m[i][j]*s; return r; }
    vec3 operator*(const vec3& v) const {
        return { m[0][0]*v.x+m[0][1]*v.y+m[0][2]*v.z,
                 m[1][0]*v.x+m[1][1]*v.y+m[1][2]*v.z,
                 m[2][0]*v.x+m[2][1]*v.y+m[2][2]*v.z };
    }
    bool invert(mat3& out) const {
        double a=m[0][0],b=m[0][1],c=m[0][2], d=m[1][0],e=m[1][1],f=m[1][2], g=m[2][0],h=m[2][1],i=m[2][2];
        double A=e*i-f*h, B=-(d*i-f*g), C=d*h-e*g;
        double det = a*A+b*B+c*C;
        if (std::abs(det) < 1e-15) return false;
        double inv = 1.0/det;
        out.m[0][0] = A*inv; out.m[0][1] =-(b*i-c*h)*inv; out.m[0][2] = (b*f-c*e)*inv;
        out.m[1][0] = B*inv; out.m[1][1] =(a*i-c*g)*inv;  out.m[1][2] = -(a*f-c*d)*inv;
        out.m[2][0] = C*inv; out.m[2][1] =-(a*h-b*g)*inv; out.m[2][2] = (a*e-b*d)*inv;
        return true;
    }
};

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

struct ahrs {

};

}

#endif