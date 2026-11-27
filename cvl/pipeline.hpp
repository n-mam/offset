#ifndef PIPELINE_HPP
#define PIPELINE_HPP

#include <atomic>
#include <vector>
#include <chrono>
#include <fstream>

#include <geometry.hpp>
#include <detector.hpp>
#include <tracker.hpp>

#include <opencv2/core.hpp>

namespace cvl {

struct pipeline {

    enum stage {
        face_detection = 1u << 0,
        face_recognition = 1u << 1,
        object_detection = 1u << 2,
        bgk_subtraction = 1u << 3,
        length_detection = 1u << 4,
    };

    pipeline(spcc cc) {
        _cc = cc;
        _tracker = std::make_unique<cvl::Tracker>();
        _faceDetector = std::make_unique<cvl::FaceDetector>();
        _objectDetector = std::make_unique<cvl::ObjectDetector>("person");
        _backgroundSubtractor = std::make_unique<cvl::BackgroundSubtractor>();
        _faceRecognizer = std::make_unique<cvl::FaceRecognizer>(
            std::getenv("CVL_MODELS_ROOT") + std::string("FaceRecognition/fr.csv"));
        _thread = std::thread(&pipeline::detectionSaveThread, this);
    }

    ~pipeline() {
        _stop.store(true, std::memory_order_relaxed);
        if (_thread.joinable()) {
            _thread.join();
        }
    }

    auto filterRightAngleContours(const cv::Mat& frame) {
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

    auto detectMotion(cv::Mat& frame) {
        auto bbs = _backgroundSubtractor->Detect(frame,_cc);
        for (const auto& bb : bbs) {
            cv::rectangle(frame, bb, cv::Scalar(0, 255, 0), 1);
            cv::putText(frame, std::to_string((int)(bb.width * bb.height)),
                cv::Point((int)bb.x, (int)(bb.y - 5)), cv::FONT_HERSHEY_SIMPLEX,
                    0.5, cv::Scalar(0, 0, 255), 1);
        }
        return bbs;
    }

    auto detectLength(cv::Mat& frame) {
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

    auto detectFaces(cv::Mat& frame) {
        return _faceDetector->Detect(frame, _cc);
    }

    auto detectObjects(cv::Mat& frame) {
        return _objectDetector->Detect(frame, _cc);
    }

    auto faceRecognition(cv::Mat& frame) {
        return _faceRecognizer->predict(frame, _cc);
    }

    auto execute(cv::Mat& frame) {
        if (frame.empty()) return;
        Detections detections;
        int stages = _cc->_stages;
        if (_cc->_flags & 2) {
            _tracker->updateTrackingContexts(frame, _cc);
        }
        if (stages & stage::face_detection) {
            detections = detectFaces(frame);
        }
        if (stages & stage::object_detection) {
            detections = detectObjects(frame);
        }
        if (stages & stage::bgk_subtraction) {
            detections = detectMotion(frame);
        }
        if (stages & stage::length_detection) {
            detectLength(frame);
        }

        cvl::Detector::FilterDetections(detections, frame);

        for (auto i = 0; i < detections.size(); i++) {
            std::string label;
            cvl::DetectionResult r;
            const auto& roi = detections[i];
            r._mat = frame(roi).clone();
            if (_cc->_flags & stage::object_detection) {
                // match this detection with all tracking contexts
                if (_tracker->matchDetectionWithTrackingContext(roi, frame)) {
                    label += "T ";
                } else {
                    _tracker->addNewTrackingContext(roi, frame);
                }
            }
            if ((stages & stage::face_detection) && (stages & stage::face_recognition)) {
                const auto& [id, confidence] = faceRecognition(r._mat);
                if (id > 0 && confidence > 0) {
                    label += _faceRecognizer->getTagFromId(id) + ": " +
                        geometry::toStringWithPrecision<2>(confidence);
                }
            }
            if (!_cc->_resultsFolder.empty()) {
                r._stages = stages;
                r._ts = duration_cast<std::chrono::microseconds>(
                    std::chrono::system_clock::now().time_since_epoch()).count();
                _detectionsQueue.enqueue(r);
            }
            cv::rectangle(frame, roi, cv::Scalar(0, 255, 0), _cc->_bbThickness);
            cv::putText(frame, label, cv::Point((int)roi.x, (int)(roi.y - 5)),
                    cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 0, 255), _cc->_bbThickness);
        }
    }

    protected:

    auto compute_ema(double current, double previous, double alpha) {
        return alpha * current + (1.0 - alpha) * previous;
    }

    void detectionSaveThread() {
        while (!_stop.load(std::memory_order_relaxed)) {
            if (!_cc->_resultsFolder.empty()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(350));
                continue;
            }
            auto d = _detectionsQueue.dequeue();
            if (d.empty()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                continue;
            }
            cvl::geometry::saveMatAsImage(d._mat, _cc->_resultsFolder
                    + "/" + std::to_string(d._ts), ".jpg");
        }
    }

    spcc _cc;
    std::thread _thread;
    std::atomic<bool> _stop = {false};
    std::unique_ptr<cvl::Tracker> _tracker = nullptr;
    cvl::queue<cvl::DetectionResult> _detectionsQueue;
    std::unique_ptr<cvl::FaceRecognizer> _faceRecognizer;
    std::unique_ptr<cvl::FaceDetector> _faceDetector = nullptr;
    std::unique_ptr<cvl::ObjectDetector> _objectDetector = nullptr;
    std::unique_ptr<cvl::BackgroundSubtractor> _backgroundSubtractor = nullptr;
};

}

#endif