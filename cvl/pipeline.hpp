#ifndef PIPELINE_HPP
#define PIPELINE_HPP

#include <vector>
#include <chrono>
#include <fstream>

#include <detector.hpp>
#include <geometry.hpp>

#include <opencv2/core.hpp>

namespace cvl {

using namespace std::chrono;

struct pipeline {

    public:

    pipeline() {
        _thread = std::thread(&pipeline::detectionSaveThread, this);
        _faceDetector = std::make_unique<cvl::FaceDetector>();
        _objectDetector = std::make_unique<cvl::ObjectDetector>("person");
        _backgroundSubtractor = std::make_unique<cvl::BackgroundSubtractor>();
        _faceRecognizer = std::make_unique<cvl::FaceRecognizer>(
            std::getenv("CVL_MODELS_ROOT") + std::string("FaceRecognition/fr.csv"));
    }

    ~pipeline() {
        _stop = true;
        if (_thread.joinable())
        _thread.join();
    }

    inline auto filterRightAngleContours(const cv::Mat& frame) {
        std::vector<cv::Vec4i> hierarchy;
        std::vector<std::vector<cv::Point>> contours, filtered_contours;
        cv::findContours(frame, contours, hierarchy, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
        std::vector<cv::Point> poly;
        for (size_t i = 0; i < contours.size(); i++) {
            cv::approxPolyDP(contours[i], poly, arcLength(contours[i], true) * 0.02, true);
            if (poly.size() == 4 &&
                cv::isContourConvex(poly) &&
                cv::contourArea(poly) > 1000) {
                double maxCosine = 0;
                for(int j = 2; j < 5; j++) {
                    // find the maximum cosine of the angle between joint edges
                    double cosine = fabs(geometry::angle(poly[j%4], poly[j-2], poly[j-1]));
                    maxCosine = MAX(maxCosine, cosine);
                }
                // if cosines of all angles are small
                // (all angles are ~90 degree) then write quandrange
                // vertices to resultant sequence
                if (maxCosine < 0.25) {
                    filtered_contours.push_back(poly);
                }
            }
        }
        return filtered_contours;
    }

    inline auto detectMotion(cv::Mat& frame, int *config) {
        auto bbs = _backgroundSubtractor->Detect(frame, config);
        for (const auto& bb : bbs) {
            cv::rectangle(frame, bb, cv::Scalar(0, 255, 0), 1);
            cv::putText(frame, std::to_string((int)(bb.width * bb.height)),
                cv::Point((int)bb.x, (int)(bb.y - 5)), cv::FONT_HERSHEY_SIMPLEX,
                0.5, cv::Scalar(0, 0, 255), 1);
        }
        return bbs;
    }

    inline auto detectLength(cv::Mat& frame) {
        auto cmpp =  cvl::Detector::detectArucoMarker(frame);
        auto thresh = cvl::geometry::getBlurGreyThresholdFrame(frame);
        auto filtered_contours = filterRightAngleContours(thresh);
        for (const auto& contour : filtered_contours) {
            auto rect = cv::boundingRect(contour);
            cv::putText(frame, "[" + geometry::toStringWithPrecision<1>(rect.width * cmpp) +
                "," + geometry::toStringWithPrecision<1>(rect.height * cmpp) + "]" ,
                cv::Point(rect.x, rect.y - 2), cv::FONT_HERSHEY_SIMPLEX, 0.3, {0,0,0}, 1);
        }
        // draw filtered contours on the original image
        cv::drawContours(frame, filtered_contours, -1, cv::Scalar(0, 255, 0), 2);
    }

    inline auto detectFaces(cv::Mat& frame, int *config) {
        return _faceDetector->Detect(frame, config);
    }

    inline auto detectObjects(cv::Mat& frame, int *config) {
        return _objectDetector->Detect(frame, config);
    }

    inline auto faceRecognition(cv::Mat& frame, int *config) {
        return _faceRecognizer->predict(frame, config);
    }

    inline auto execute(cv::Mat& frame, int *config, const std::string& resultsPath) {
        if (frame.empty()) {
            ERR << "empty frame grabbed";
            return;
        }

        Detections detections;
        int stages = config[IDX_PIPELINE_STAGES];

        if (stages & 1) {
            detections = detectFaces(frame, config);
        }
        if (stages & 2) {
            detections = detectObjects(frame, config);
        }
        if (stages & 4) {
            detections = detectMotion(frame, config);
        }
        if (stages & 8) {

        }
        if (stages & 16) {
            detectLength(frame);
        }

        cvl::Detector::FilterDetections(detections, frame);

        _count++;
        _save = (bool)resultsPath.length();
        _save_path = resultsPath;

        for (auto i = 0; i < detections.size(); i++) {
            auto roi = detections[i];
            cvl::DetectionResult r;
            if ((stages & 8) && (stages & 1)) {
                cv::Mat gray;
                r._roi = frame(roi).clone();
                cv::cvtColor(r._roi, gray, cv::COLOR_BGR2GRAY);
                const auto& [tag, confidence] = faceRecognition(gray, config);
                if (tag.length() && confidence > 0) {
                    cv::putText(frame, tag + " : " + geometry::toStringWithPrecision<2>(confidence),
                        cv::Point((int)roi.x, (int)(roi.y - 5)), cv::FONT_HERSHEY_SIMPLEX,
                        1.0, cv::Scalar(255, 255, 255), config[IDX_BOUNDINGBOX_THICKNESS]);
                }
            }

            if (_save && ((_count % config[IDX_SKIP_FRAMES])) == 0) {
                r._stages = stages;
                r._frame = _count;
                r._detection = i;
                if (r._roi.empty()) {
                    r._roi = frame(roi).clone();
                }
                r._ts = duration_cast<seconds>(system_clock::now()
                    .time_since_epoch()).count();
                _detectionsQueue.enqueue(r);
            }

            cv::rectangle(frame, roi, cv::Scalar(0, 255, 0), config[IDX_BOUNDINGBOX_THICKNESS]);
        }
    }

    protected:

    bool _stop = false;
    bool _save = false;
    uint32_t _count = 0;
    std::thread _thread;
    std::string _save_path;
    cvl::queue<cvl::DetectionResult> _detectionsQueue;
    std::unique_ptr<cvl::FaceRecognizer> _faceRecognizer;
    std::unique_ptr<cvl::FaceDetector> _faceDetector = nullptr;
    std::unique_ptr<cvl::ObjectDetector> _objectDetector = nullptr;
    std::unique_ptr<cvl::BackgroundSubtractor> _backgroundSubtractor = nullptr;

    void detectionSaveThread() {
        while (!_stop) {
            if (!_save || _save_path.length() == 0) {
                std::this_thread::sleep_for(milliseconds(350));
                continue;
            }
            auto d = _detectionsQueue.dequeue();
            if (d.empty()) {
                std::this_thread::sleep_for(milliseconds(50));
                continue;
            }
            cvl::geometry::saveMatAsImage(d._roi, _save_path + "/" +
                    std::to_string(d._frame) + "_" +
                    std::to_string(d._detection) + "_" +
                    std::to_string(d._ts), ".jpg");
        }
    }
};

}

#endif