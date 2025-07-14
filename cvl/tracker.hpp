#ifndef TRACKER_HPP
#define TRACKER_HPP

#include <vector>
#include <functional>

#include <geometry.hpp>
#include <detector.hpp>

#include <opencv2/opencv.hpp>
#include <opencv2/tracking/tracking.hpp>

namespace cvl {

struct TrackingContext {

    size_t id;
    int _lostCount = 0;
    std::vector<cv::Rect2d> _trail;
    cv::Ptr<cv::Tracker> cvTracker;
    std::vector<cv::Mat> _thumbnails;

    bool is_frozen(void) {
        // valid only for FOV where the subject is
        // moving either top-down or left to right
        if (_trail.size() >= 8) {
            auto& last = _trail[_trail.size() - 1];
            auto& prev = _trail[_trail.size() - 8];
            auto d = cvl::geometry::distance(cvl::geometry::getRectCenter(last),
                cvl::geometry::getRectCenter(prev));
            if (d <= 2) return true;
        }
        return false;
    }
};

struct Tracker {

    Tracker() {}

    ~Tracker() {
        ClearAllContexts();
    }

    void ClearAllContexts(void) {
        _trackingContexts.clear();
    }

    size_t GetTrackingContextCount(void) {
        return _trackingContexts.size();
    }

    virtual void RenderDisplacementAndPaths(cv::Mat& m, bool isTest = true) {
        for (auto& tc : _trackingContexts) {
            // Displacement
            auto first = cvl::geometry::getRectCenter(tc._trail.front());
            auto last = cvl::geometry::getRectCenter(tc._trail.back());
            cv::line(m, first, last, cv::Scalar(0, 0, 255), 1);
            // path
            for (size_t i = 1; i < tc._trail.size() - 1; ++i)
            {
                auto&& f = cvl::geometry::getRectCenter(tc._trail[i]);
                auto&& b = cvl::geometry::getRectCenter(tc._trail[i-1]);
                cv::line(m, f, b, cv::Scalar(0, 255, 0), 1);
            }
            auto& bb = tc._trail.back();
            cv::rectangle(m, bb, cv::Scalar(0, 0, 255), 1, 1); //tracking red
        }
    }

    auto updateTrackingContexts(cv::Mat& frame) {
        for (int i = _trackingContexts.size() - 1; i >= 0; i--) {
            auto& tc = _trackingContexts[i];
            cv::Rect bb;
            bool rc = tc.cvTracker->update(frame, bb);
            if (rc && cvl::geometry::isRectInsideMat(bb, frame)) {
                tc._trail.push_back(bb);
                tc._lostCount = 0;
            } else {
                tc._lostCount++;
                std::cout << "Tracker " << tc.id << " _lostCount: " << tc._lostCount << std::endl;
            }
            if (tc._lostCount > 5) {
                auto id = tc.id;
                tc.cvTracker.release();
                _trackingContexts.erase(_trackingContexts.begin() + i);
                std::cout << "Removed Tracker with id: " << id << " (frozen)" << std::endl;
                continue;
            }
        }
    }

    auto matchDetectionWithTrackingContext(const cv::Rect2d& roi, cv::Mat& mat) {
        for (auto& t : _trackingContexts) {
            auto& last = t._trail.back();
            if (cvl::geometry::doesRectOverlapRect(roi, last)) {
                t._thumbnails.emplace_back(mat(roi).clone());
                return true;
            }
        }
        return false;
    }

    void addNewTrackingContext(const cv::Rect2d& roi, const cv::Mat& mat) {
        TrackingContext tc;
        tc.id = _trackingContexts.size();
        cv::TrackerCSRT::Params params;
        params.psr_threshold = 0.04f; //0.035f;
        //param.template_size = 150;
        //param.admm_iterations = 3;
        tc.cvTracker = cv::TrackerCSRT::create(params);
        tc._trail.push_back(roi);
        tc.cvTracker->init(mat, roi);
        cv::rectangle(mat, roi, cv::Scalar(0, 0, 0 ), 2, 1);  // white
        _trackingContexts.push_back(tc);
        std::cout << "+ Tracker with id: " << tc.id << std::endl;
    }

    protected:

    std::vector<TrackingContext> _trackingContexts;
};

} //namespace cvl

#endif //TRACKER_HPP