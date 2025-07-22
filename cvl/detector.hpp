#ifndef DETECTOR_HPP
#define DETECTOR_HPP

#include <osl/log>

#include <geometry.hpp>

#include "opencv2/face.hpp"
#include <opencv2/dnn.hpp>
#include <opencv2/aruco.hpp>
#include <opencv2/bgsegm.hpp>
#ifdef HAVE_OPENCV_CUDAFEATURES2D
#include <opencv2/core/cuda.hpp>
#endif

#include <string>
#include <vector>
#include <chrono>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <unordered_map>

namespace cvl {

using Detections = std::vector<cv::Rect2d>;

constexpr double marker_length_cm = 5.3;

constexpr int IDX_MOCAP_ALGO = 0;
constexpr int IDX_SKIP_FRAMES = 1;
constexpr int IDX_PIPELINE_FLAGS = 2;
constexpr int IDX_PIPELINE_STAGES = 3;
constexpr int IDX_FACE_CONFIDENCE = 4;
constexpr int IDX_OBJECT_CONFIDENCE = 5;
constexpr int IDX_FACEREC_CONFIDENCE = 6;
constexpr int IDX_MOCAP_EXCLUDE_AREA = 7;
constexpr int IDX_BOUNDINGBOX_THICKNESS = 8;
constexpr int IDX_BOUNDINGBOX_INCREMENT = 9;

inline auto getModelRootDir() {
    return std::getenv("CVL_MODELS_ROOT");
}

struct DetectionResult {
    int64_t       _ts;
    cv::Mat       _mat;
    cv::Size      _dim;
    std::string   _frId;
    uint32_t      _frame;
    int           _stages;

    DetectionResult(){ _ts = -1; }

    inline auto empty() {
        return (_ts == -1);
    }

    inline auto clone() {
        DetectionResult out = *this;
        out._mat = this->_mat.clone();
        return std::move(out);
    }
};

struct Detector {

    Detector() {}

    Detector(const std::string& config, const std::string& weight) {
        _configFile = getModelRootDir() + config;
        _weightFile = std::getenv("CVL_MODELS_ROOT") + weight;
        try {
            _network = cv::dnn::readNetFromCaffe(_configFile, _weightFile);
        } catch(const std::exception& e) {
            ERR << "Detector, exception : " << e.what();
        }
        #ifdef HAVE_OPENCV_CUDAFEATURES2D
        if (cv::cuda::getCudaEnabledDeviceCount()) {
            _network.setPreferableBackend(cv::dnn::Backend::DNN_BACKEND_CUDA);
            _network.setPreferableTarget(cv::dnn::Target::DNN_TARGET_CUDA);
            LOG << "CUDA backend and target enabled for inference";
        }
        else
        #endif 
        {
            _network.setPreferableBackend(cv::dnn::Backend::DNN_BACKEND_OPENCV);
            _network.setPreferableTarget(cv::dnn::Target::DNN_TARGET_CPU);
            LOG << "OpenCV backend and cpu target enabled for inference";
        }
    }

    virtual ~Detector() {}

    virtual Detections Detect(cv::Mat& frame, int *config) = 0;

    // auxiliary detections and filters

    inline static auto detectArucoMarker(cv::Mat& frame) {
        double cmpp = 0;
        std::vector<int> markerIds;
        std::vector<std::vector<cv::Point2f>> allMarkerCorners;
        std::vector<std::vector<cv::Point2f>> rejectedCandidates;
        auto markerDictionary = new cv::aruco::Dictionary();
        *markerDictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
        cv::aruco::detectMarkers(frame, cv::Ptr<cv::aruco::Dictionary>(markerDictionary), allMarkerCorners, markerIds);
        // cv::aruco::drawDetectedMarkers(frame, allMarkerCorners, markerIds, cv::Scalar(0, 0, 255));
        if (markerIds.size() > 0) {
            // assume only one marker for now
            auto edge_distance = geometry::distance<cv::Point2d>(allMarkerCorners[0][0], allMarkerCorners[0][1]);
            cmpp = marker_length_cm / edge_distance;
            DBG << "Marker Id : " << markerIds[0];
        }

        return cmpp;
    }

    inline static auto FilterDetections(Detections& detections, cv::Mat& m) {
        for (auto&& it = detections.begin(); it != detections.end(); ) {
            auto& roi = *it;
            bool remove = (roi.x < 0 || roi.x + roi.width > m.cols
                || roi.y < 0 || roi.y + roi.height > m.rows);
            //exclude near-to-frame detections, mark white
            if ((roi.y < 5) || ((roi.y + roi.height) > (m.rows - 5))) {
                cv::rectangle(m, roi, cv::Scalar(255, 255, 255), 1, 1);
                remove = true;
            }
            if (remove) {
                it = detections.erase(it);
            } else {
                it++;
            }
        }
    }

    protected:

    std::string _target;
    cv::dnn::Net _network;
    std::string _configFile;
    std::string _weightFile;
};

struct FaceDetector : public Detector {

    FaceDetector() : Detector(
        "FaceDetection/deploy.prototxt",
        "FaceDetection/res10_300x300_ssd_iter_140000.caffemodel") {}

    ~FaceDetector() {}

    virtual Detections Detect(cv::Mat& frame, int *config) override {
        Detections out;
        cv::Mat inputBlob = cv::dnn::blobFromImage(
                        frame,
                        1.0,
                        cv::Size(300, 300),
                        cv::Scalar(104.0, 177.0, 123.0),
                        false,
                        false);

        _network.setInput(inputBlob);
        cv::Mat detection = _network.forward();
        cv::Mat detectionMat(detection.size[2], detection.size[3], CV_32F, detection.ptr<float>());
        for (int i = 0; i < detectionMat.rows; ++i) {
            float _confidence = detectionMat.at<float>(i, 2);
            if (_confidence > ((double)config[IDX_FACE_CONFIDENCE] / 10)) {
                int x1 = static_cast<int>(detectionMat.at<float>(i, 3) * frame.cols);
                int y1 = static_cast<int>(detectionMat.at<float>(i, 4) * frame.rows);
                int x2 = static_cast<int>(detectionMat.at<float>(i, 5) * frame.cols);
                int y2 = static_cast<int>(detectionMat.at<float>(i, 6) * frame.rows);

                auto rect = cv::Rect2d(x1, y1, x2 - x1, y2 - y1);

                if (cvl::geometry::isRectInsideMat(rect, frame)) {
                    out.emplace_back(
                        config[cvl::IDX_BOUNDINGBOX_INCREMENT] != 0 ?
                            cvl::geometry::resizeRectByWidth(rect,
                                config[cvl::IDX_BOUNDINGBOX_INCREMENT]) : rect);
                }
            }
        }
        return out;
    }
};

struct ObjectDetector : public Detector {

    ObjectDetector(const std::string& target) : Detector(
      "ObjectDetection/MobileNetSSD_deploy.prototxt",
      "ObjectDetection/MobileNetSSD_deploy.caffemodel"){
      _target = target;
    }

    virtual Detections Detect(cv::Mat& frame, int *config) override {
        Detections out;
        cv::Mat inputBlob = cv::dnn::blobFromImage(
                        frame,
                        0.007843f,
                        cv::Size(300, 300),
                        cv::Scalar(127.5, 127.5, 127.5),
                        false,
                        false);

        _network.setInput(inputBlob);
        cv::Mat detection = _network.forward();
        cv::Mat detectionMat(detection.size[2], detection.size[3], CV_32F, detection.ptr<float>());
        for (int i = 0; i < detectionMat.rows; ++i) {
            float _confidence = detectionMat.at<float>(i, 2);
            if (_confidence > ((double)config[IDX_OBJECT_CONFIDENCE] / 10)) {
                int idx, x1, y1, x2, y2;
                idx = static_cast<int>(detectionMat.at<float>(i, 1));
                if (1) {//_objectClass[idx] == _target)
                    x1 = static_cast<int>(detectionMat.at<float>(i, 3) * frame.cols);
                    y1 = static_cast<int>(detectionMat.at<float>(i, 4) * frame.rows);
                    x2 = static_cast<int>(detectionMat.at<float>(i, 5) * frame.cols);
                    y2 = static_cast<int>(detectionMat.at<float>(i, 6) * frame.rows);

                    auto rect = cv::Rect2d(x1, y1, x2 - x1, y2 - y1);
                    if (cvl::geometry::isRectInsideMat(rect, frame)) {
                        out.emplace_back(
                            config[cvl::IDX_BOUNDINGBOX_INCREMENT] != 0 ?
                                cvl::geometry::resizeRectByWidth(rect,
                                    config[cvl::IDX_BOUNDINGBOX_INCREMENT]) : rect);
                    }
                }
            }
        }
        return out;
    }

    protected:

    inline static const std::string _objectClass[] = {
      "background", "aeroplane", "bicycle", "bird", "boat",
	    "bottle", "bus", "car", "cat", "chair", "cow", "diningtable",
	    "dog", "horse", "motorbike", "person", "pottedplant", "sheep",
	    "sofa", "train", "tvmonitor"
    };
};

struct BackgroundSubtractor : public Detector {

    BackgroundSubtractor() : Detector() {
        pBackgroundSubtractor[0] = cv::bgsegm::createBackgroundSubtractorMOG();
        pBackgroundSubtractor[1] = cv::bgsegm::createBackgroundSubtractorCNT();
        pBackgroundSubtractor[2] = cv::bgsegm::createBackgroundSubtractorGMG();
        pBackgroundSubtractor[3] = cv::bgsegm::createBackgroundSubtractorGSOC();
        pBackgroundSubtractor[4] = cv::bgsegm::createBackgroundSubtractorLSBP();
    }

    virtual Detections Detect(cv::Mat& frame, int *config) override {
        cv::Mat fgMask;
        cv::Mat gray, blurred;
        cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
        cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);
        pBackgroundSubtractor[config[IDX_MOCAP_ALGO]]->apply(blurred, fgMask, 0.05);
        cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));
        cv::morphologyEx(fgMask, fgMask, cv::MORPH_OPEN, kernel);
        cv::morphologyEx(fgMask, fgMask, cv::MORPH_CLOSE, kernel);  // optional
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(fgMask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
        Detections out;
        double areaThreshold = (double)config[IDX_MOCAP_EXCLUDE_AREA];
        for (size_t i = 0; i < contours.size(); i++) {
            if (cv::contourArea(contours[i]) < areaThreshold) {
                continue;
            }
            auto bb = cv::boundingRect(contours[i]);
            out.emplace_back(bb);
        }
        return out;
    }

    protected:

    cv::Ptr<cv::BackgroundSubtractor> pBackgroundSubtractor[5] = {nullptr};
};

struct FaceRecognizer {

    FaceRecognizer(const std::string& csv) {
        _id_tag_map.reserve(256);
        try {
            read_csv(csv);
        } catch (const std::exception& e) {
            std::cerr << e.what() << std::endl;
        }
        _model = cv::face::LBPHFaceRecognizer::create();
        _model->setRadius(1);
        _model->setNeighbors(8);
        _model->setGridX(4);
        _model->setGridY(4);
        if (_images.size() && _ids.size()) {
            _model->train(_images, _ids);
        }
    }

    ~FaceRecognizer(){}

    auto getTagFromId(int id) {
        std::string tag;
        try {
            tag = _id_tag_map.at(id);
        } catch(const std::exception& e) {
            ERR << e.what() << " " << id;
        }
        return tag;
    }

    auto predict(const cv::Mat& mat, int *config) {
        int id = -1;
        double confidence = 0.0;
        cv::Mat gray;
        cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
        cv::resize(gray, gray, cv::Size(100, 100));
        _model->predict(gray, id, confidence);
        std::pair<int, double> pair = {-1, 0.0};
        if (confidence <= config[cvl::IDX_FACEREC_CONFIDENCE]) {
            pair = std::make_pair(id, confidence);
        }
        return pair;
    }

    private:

    std::vector<int> _ids;
    std::vector<cv::Mat> _images;
    std::vector<std::string> _tags;
    cv::Ptr<cv::face::LBPHFaceRecognizer> _model;
    std::unordered_map<int, std::string> _id_tag_map;

    void read_csv(const std::string& filename, char separator = ';') {
        std::ifstream file(filename.c_str(), std::ifstream::in);
        if (!file) {
            ERR << "read_csv Invalid input file";
            return;
        }
        std::string line, path, id, tag;
        while (getline(file, line)) {
            std::stringstream liness(line);
            std::getline(liness, path, separator);
            std::getline(liness, id, separator);
            std::getline(liness, tag);
            if(!path.empty() && !id.empty() && !tag.empty()) {
                auto img = cv::imread(path, cv::IMREAD_GRAYSCALE);
                if (img.empty()) {
                    std::cout << "Warning: Could not load image: " << path << std::endl;
                    continue;
                }
                cv::resize(img, img, cv::Size(100, 100));
                _images.push_back(img);
                _tags.push_back(tag);
                auto i = std::atoi(id.c_str());
                _ids.push_back(i);
                _id_tag_map.emplace(i, tag);
            }
        }
    }
};

}

#endif