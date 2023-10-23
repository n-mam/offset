#ifndef PIPELINE_HPP
#define PIPELINE_HPP

#include <vector>
#include <chrono>
#include <fstream>

#include <facerec.hpp>
#include <detector.hpp>
#include <geometry.hpp>

#include <opencv2/core.hpp>

namespace cvl {

using namespace std::chrono;

constexpr int IDX_PIPELINE_STAGES = 0;
constexpr int IDX_FACE_CONFIDENCE = 1;
constexpr int IDX_OBJECT_CONFIDENCE = 2;
constexpr int IDX_FACEREC_CONFIDENCE = 3;
constexpr int IDX_MOCAP_EXCLUDE_AREA = 4;
constexpr int IDX_BOUNDINGBOX_THICKNESS = 5;

class pipeline
{
    public:

    pipeline()
    {
        //_thread = std::thread(&pipeline::pipelineThread, this);

        _faceDetector = std::make_unique<cvl::FaceDetector>();

        _objectDetector = std::make_unique<cvl::ObjectDetector>("person");

        _backgroundSubtractor = std::make_unique<cvl::BackgroundSubtractor>("gmg");

        //_faceRec = std::make_unique<cvl::facerec>("../MODELS/FaceRecognition/fr.csv");
    }

    ~pipeline()
    {
        _stop = true;
        if (_thread.joinable())
        _thread.join();
    }

    inline auto filterRightAngleContours(const cv::Mat& frame)
    {
        std::vector<cv::Vec4i> hierarchy;
        std::vector<std::vector<cv::Point>> contours, filtered_contours;

        cv::findContours(frame, contours, hierarchy, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

        std::vector<cv::Point> poly;

        for (size_t i = 0; i < contours.size(); i++)
        {
            cv::approxPolyDP(contours[i], poly, arcLength(contours[i], true) * 0.02, true);

            if (poly.size() == 4 &&
                cv::isContourConvex(poly) &&
                cv::contourArea(poly) > 1000)
            {
                double maxCosine = 0;
                for(int j = 2; j < 5; j++)
                {
                    // find the maximum cosine of the angle between joint edges
                    double cosine = fabs(geometry::angle(poly[j%4], poly[j-2], poly[j-1]));
                    maxCosine = MAX(maxCosine, cosine);
                }
                // if cosines of all angles are small
                // (all angles are ~90 degree) then write quandrange
                // vertices to resultant sequence
                if (maxCosine < 0.25)
                {
                    filtered_contours.push_back(poly);
                }
            }
        }

        return filtered_contours;
    }

    inline auto detectMotion(cv::Mat& frame, double areaThreshold)
    {
        auto bbs = _backgroundSubtractor->Detect(frame, areaThreshold);

        for (const auto& bb : bbs)
        {
            cv::rectangle(frame, bb, cv::Scalar(0, 255, 0), 1);
            cv::putText(frame, std::to_string((int)(bb.width * bb.height)),
                cv::Point((int)bb.x, (int)(bb.y - 5)), cv::FONT_HERSHEY_SIMPLEX,
                0.5, cv::Scalar(0, 0, 255), 1);
        }

        return bbs;
    }

    inline auto detectLength(cv::Mat& frame)
    {
        auto cmpp =  cvl::Detector::detectArucoMarker(frame);

        auto thresh = cvl::geometry::getBlurGreyThresholdFrame(frame);

        auto filtered_contours = filterRightAngleContours(thresh);

        for (const auto& contour : filtered_contours)
        {
            auto rect = cv::boundingRect(contour);

            std::ostringstream oss;
            oss.precision(2);

            // oss << "[" << std::fixed << rect.width;
            // oss << "," << std::fixed << rect.height;
            oss << "[" << std::fixed << rect.width * cmpp;
            oss << "," << std::fixed << rect.height * cmpp << "]";

            cv::putText(frame, oss.str().c_str(), cv::Point(rect.x, rect.y - 2),
                cv::FONT_HERSHEY_SIMPLEX, 0.3, {0,0,0}, 1);
        }

        // draw filtered contours on the original image
        cv::drawContours(frame, filtered_contours, -1, cv::Scalar(0, 255, 0), 2);
    }

    inline auto detectFaces(cv::Mat& frame, double confidence)
    {
        return _faceDetector->Detect(frame, confidence);
    }

    inline auto detectObjects(cv::Mat& frame, double confidence)
    {
        return _objectDetector->Detect(frame, confidence);
    }

    inline auto faceRecognition(cv::Mat& frame)
    {
        return _faceRec->predict(frame);
    }

    inline auto execute(cv::Mat& frame, int *config)
    {
        if (frame.empty()) {
            ERR << "empty frame grabbed";
            return;
        }

        Detections detections;

        int stages = config[IDX_PIPELINE_STAGES];

        if (stages & 1) {
            detections = detectFaces(frame, (double)config[IDX_FACE_CONFIDENCE] / 10);
        } else if (stages & 2) {
            detections = detectObjects(frame, (double)config[IDX_OBJECT_CONFIDENCE] / 10);
        } else if (stages & 4) {
            detections = detectMotion(frame, (double)config[IDX_MOCAP_EXCLUDE_AREA] / 10);
        } else if (stages & 8) {
            // facerec config[IDX_FACEREC_CONFIDENCE] /10
        } else if (stages & 16) {
            //detections = detectLength(frame);
        }

        cvl::Detector::FilterDetections(detections, frame);

        for (const auto& roi : detections)
        {
            cvl::DetectionResult r;

            // r._stage = "face";
            // r._roi = frame(roi).clone(),
            // r._ts = duration_cast<seconds>(system_clock::now()
            //     .time_since_epoch()).count();
            // _detectionsQueue.enqueue(r);

            if (stages & 8) {
                cv::Mat gray;
                cv::cvtColor(r._roi, gray, cv::COLOR_BGR2GRAY);
                const auto& [tag, confidence] = faceRecognition(gray);

                if (tag.length() && confidence > 0.0)
                    cv::putText(frame, tag + " : " + std::to_string(confidence),
                        cv::Point((int)roi.x, (int)(roi.y - 5)), cv::FONT_HERSHEY_SIMPLEX,
                        0.5, cv::Scalar(0, 0, 255), 1);
            }

            cv::rectangle(frame, roi, cv::Scalar(0, 255, 0), config[IDX_BOUNDINGBOX_THICKNESS]);
        }
    }

    protected:

    bool _stop = false;

    std::thread _thread;

    cvl::queue<cvl::DetectionResult> _detectionsQueue;

    std::unique_ptr<cvl::facerec> _faceRec;

    std::unique_ptr<cvl::FaceDetector> _faceDetector = nullptr;

    std::unique_ptr<cvl::ObjectDetector> _objectDetector = nullptr;

    std::unique_ptr<cvl::BackgroundSubtractor> _backgroundSubtractor = nullptr;

    void pipelineThread()
    {
        static uint32_t count = 0;

        while (!_stop)
        {
            auto d = _detectionsQueue.dequeue();

            if (d.empty())
            {
                std::this_thread::sleep_for(milliseconds(50));
                continue;
            }

            cvl::geometry::saveMatAsImage(
                d._roi, std::to_string(++count) + "_" + std::to_string(d._ts), ".jpg");
        }
    }
};

}

#endif