#ifndef GEOMETRY_HPP
#define GEOMETRY_HPP

#include <iostream>

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc/imgproc.hpp>

namespace cvl::geometry {

// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
inline double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

inline bool isRectInsideMat(const cv::Rect2d& r, const cv::Mat& m) {
    return (static_cast<cv::Rect>(r).area() ==
        (static_cast<cv::Rect>(r) & cv::Rect(0, 0, m.cols, m.rows)).area());
}

inline bool isRectInsideRect(const cv::Rect2d& r1, const cv::Rect2d& r2) {
    return (static_cast<cv::Rect>(r1).area() ==
        ((static_cast<cv::Rect>(r1) & static_cast<cv::Rect>(r2))).area());
}

inline bool doesRectOverlapMat(const cv::Rect2d& r, const cv::Mat& m) {
    return ((static_cast<cv::Rect>(r) & cv::Rect(0, 0, m.cols, m.rows)).area() > 0);
}

inline bool doesRectOverlapRect(const cv::Rect2d& r1, const cv::Rect2d& r2) {
    return (((static_cast<cv::Rect>(r1) & static_cast<cv::Rect>(r2))).area() > 0);
}

inline cv::Point getRectCenter(const cv::Rect2d& r) {
    return ((r.br() + r.tl()) * 0.5);
}

template<typename T>
inline double distance(const T& p1, const T& p2) {
    double x = p1.x - p2.x;
    double y = p1.y - p2.y;
    return sqrt((x * x) + (y * y));
}

template<typename T>
inline bool doesIntersectReferenceLine(const T& start, const T& end, int refx, int refy) {
    return false;
}

template <int N>
inline auto toStringWithPrecision(double value) {
    std::ostringstream oss;
    oss.precision(N);
    oss << std::fixed << value;
    return oss.str();
}

template<typename T>
inline auto resizeRectByWidth(const T& rect, int dx) {
    double percent = dx / rect.width;
    double w = rect.width + dx;
    double dy = (rect.height * percent);
    double h = rect.height + dy;
    return T(rect.x - dx/2, rect.y - dy/2, w, h);
}

inline auto getBlurGreyThresholdFrame(const cv::Mat& frame) {
    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    cv::GaussianBlur(gray, gray, cv::Size(7, 7), 0);
    cv::Mat thresh;
    cv::threshold(gray, thresh, 0, 255, cv::THRESH_BINARY|cv::THRESH_OTSU);
    return thresh;
}

inline auto saveMatAsImage(cv::Mat& mat, const std::string& fileName, const std::string& ext) {
    std::vector<uchar> image;
    cv::imencode(ext, mat, image);
    std::ofstream fout((fileName + ext).c_str(),
        std::ios::out|std::ios::binary);
    fout.write((const char*)&image[0], image.size());
    fout.close();
}

inline auto computeLaplacianVariance(const cv::Mat& img) {
    cv::Mat gray, laplacian;
    if (img.channels() == 3) {
        cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);
    } else {
        gray = img.clone();
    }
    cv::Laplacian(gray, laplacian, CV_64F);
    cv::Scalar mean, stddev;
    cv::meanStdDev(laplacian, mean, stddev);
    double variance = stddev[0] * stddev[0];
    return variance;
}

}

#endif