#ifndef DETECTOR_HPP
#define DETECTOR_HPP

#include <osl/log>

#include <geometry.hpp>

#include <opencv2/dnn.hpp>
#include <opencv2/aruco.hpp>
#include <opencv2/bgsegm.hpp>

#include <string>
#include <vector>
#include <chrono>
#include <filesystem>

namespace cvl {

constexpr double marker_length_cm = 2.3;
using Detections = std::vector<cv::Rect2d>;

struct DetectionResult
{
  int           _age;
  char          _gender;
  int64_t       _ts = -1;
  cv::Mat       _roi;
  cv::Size      _dim;
  std::string   _stage;
  std::string   _frTag;

  DetectionResult(){}

  inline auto empty()
  {
    return (_ts == -1);
  }

  inline auto clone()
  {
    DetectionResult out = *this;
    out._roi = this->_roi.clone();
    return std::move(out);
  }
};

class Detector
{
  public:

  Detector() {}

  Detector(const std::string& config, const std::string& weight)
  {
    _configFile = "../cvl/MODELS/" + config;
    _weightFile = "../cvl/MODELS/" + weight;

    try
    {
      _network = cv::dnn::readNetFromCaffe(_configFile, _weightFile);
    }
    catch(const std::exception& e)
    {
      ERR << "Detector, exception : " << e.what();
    }

    #ifdef HAVE_OPENCV_CUDAFEATURES2D
    if (cv::cuda::getCudaEnabledDeviceCount())
    {
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

  virtual Detections Detect(cv::Mat& frame, double confidence) = 0;

  // auxiliary detections and filters

  inline static auto detectArucoMarker(cv::Mat& frame)
  {
    double cmpp = 0;
    std::vector<int> markerIds;
    std::vector<std::vector<cv::Point2f>> allMarkerCorners;
    std::vector<std::vector<cv::Point2f>> rejectedCandidates;

    auto markerDictionary = new cv::aruco::Dictionary();

    *markerDictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);

    cv::aruco::detectMarkers(frame, cv::Ptr<cv::aruco::Dictionary>(markerDictionary), allMarkerCorners, markerIds);

    // cv::aruco::drawDetectedMarkers(frame, allMarkerCorners, markerIds, cv::Scalar(0, 0, 255));

    if (markerIds.size() > 0)
    {
      // assume only one marker for now
      auto edge_distance = geometry::distance<cv::Point2d>(allMarkerCorners[0][0], allMarkerCorners[0][1]);
      cmpp = marker_length_cm / edge_distance;
      DBG << "Marker Id : " << markerIds[0];
    }

    return cmpp;
  }

  inline static auto FilterDetections(Detections& detections, cv::Mat& m)
  {
    for (auto&& it = detections.begin(); it != detections.end(); )
    {
      bool remove = false;

      auto& roi = *it;

      remove = (roi.x < 0 || roi.x + roi.width > m.cols || roi.x < 0 || roi.y + roi.height > m.rows);

      //exclude near-to-frame detections, mark white
      if ((roi.y < 5) || ((roi.y + roi.height) > (m.rows - 5)))
      {
        cv::rectangle(m, roi, cv::Scalar(255, 255, 255), 1, 1);
        remove = true;
      }

      if (remove)
      {
        it = detections.erase(it);
      }
      else
      {
        it++;
      }
    }
  }

  protected:

  std::string _target;

  std::string _configFile;

  std::string _weightFile;

  cv::dnn::Net _network;
};

class FaceDetector : public Detector
{
  public:

  FaceDetector() : Detector(
      "FaceDetection/deploy.prototxt",
      "FaceDetection/res10_300x300_ssd_iter_140000.caffemodel") {}

  ~FaceDetector() {}

  virtual Detections Detect(cv::Mat& frame, double confidence) override
  {
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

    for (int i = 0; i < detectionMat.rows; ++i)
    {
      float _confidence = detectionMat.at<float>(i, 2);

      if (_confidence > confidence)
      {
        int x1 = static_cast<int>(detectionMat.at<float>(i, 3) * frame.cols);
        int y1 = static_cast<int>(detectionMat.at<float>(i, 4) * frame.rows);
        int x2 = static_cast<int>(detectionMat.at<float>(i, 5) * frame.cols);
        int y2 = static_cast<int>(detectionMat.at<float>(i, 6) * frame.rows);

        auto rect = cv::Rect2d(x1, y1, x2 - x1, y2 - y1);

        if (cvl::geometry::isRectInsideMat(rect, frame))
        {
          out.emplace_back(cvl::geometry::resizeRect(rect, 54));
        }
      }
    }

    return out;
  }
};

class ObjectDetector : public Detector
{
  public:

    ObjectDetector(const std::string& target) : Detector(
      "ObjectDetection/MobileNetSSD_deploy.prototxt",
      "ObjectDetection/MobileNetSSD_deploy.caffemodel")
    {
      _target = target;
    }

    virtual Detections Detect(cv::Mat& frame, double confidence) override
    {
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

      for (int i = 0; i < detectionMat.rows; ++i)
      {
        float _confidence = detectionMat.at<float>(i, 2);

        if (_confidence > confidence)
        {
          int idx, x1, y1, x2, y2;

          idx = static_cast<int>(detectionMat.at<float>(i, 1));

          if (_objectClass[idx] == _target)
          {
            x1 = static_cast<int>(detectionMat.at<float>(i, 3) * frame.cols);
            y1 = static_cast<int>(detectionMat.at<float>(i, 4) * frame.rows);
            x2 = static_cast<int>(detectionMat.at<float>(i, 5) * frame.cols);
            y2 = static_cast<int>(detectionMat.at<float>(i, 6) * frame.rows);

            auto rect = cv::Rect2d(x1, y1, x2 - x1, y2 - y1);

            if (cvl::geometry::isRectInsideMat(rect, frame))
            {
              out.emplace_back(cvl::geometry::resizeRect(rect, 40));
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

class BackgroundSubtractor : public Detector
{
  public:

    BackgroundSubtractor(const std::string& algo) : Detector()
    {
      if (algo == "mog") {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorMOG();
      } else if (algo == "cnt") {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorCNT();
      } else if (algo == "gmg") {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorGMG();
      } else if (algo == "gsoc") {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorGSOC();
      } else if (algo == "lsbp") {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorLSBP();
      } else {
         pBackgroundSubtractor = cv::bgsegm::createBackgroundSubtractorGMG();
      }
    }

    virtual Detections Detect(cv::Mat& frame, double confidence) override
    {
      cv::Mat fgMask;

      pBackgroundSubtractor->apply(frame, fgMask, -1);

      std::vector<std::vector<cv::Point>> contours;

      cv::findContours(fgMask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

      Detections out;
      auto areaThreshold = 1500;

      for (size_t i = 0; i < contours.size(); ++i)
      {
        if (cv::contourArea(contours[i]) < areaThreshold)
        {
          continue;
        }

        auto bb = cv::boundingRect(contours[i]);

        out.emplace_back(bb);
      }

      return out;
    }

  protected:

    cv::Ptr<cv::BackgroundSubtractor> pBackgroundSubtractor = nullptr;

};

}

#endif