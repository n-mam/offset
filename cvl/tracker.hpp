#ifndef TRACKER_HPP
#define TRACKER_HPP

#include <thread>
#include <vector>
#include <functional>

#include <geometry.hpp>
#include <detector.hpp>

#include <opencv2/opencv.hpp>
#include <opencv2/tracking/tracking.hpp>

#include <telegram.hpp>

namespace cvl {

struct TrackingContext {
    size_t id;
    int _lostCount = 0;
    int _foundCount = 0;
    bool _notified = false;
    cv::Ptr<cv::Tracker> cvTracker;
    std::vector<cv::Rect2d> _trail;
    std::vector<cv::Mat> _thumbnails;
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

    auto updateTrackingContexts(cv::Mat& frame, int flags) {
        for (int i = _trackingContexts.size() - 1; i >= 0; i--) {
            auto& t = _trackingContexts[i];
            cv::Rect bb;
            bool rc = t.cvTracker->update(frame, bb);
            if (rc && cvl::geometry::isRectInsideMat(bb, frame)) {
                t._trail.push_back(bb);
                t._foundCount++;
            } else {
                t._lostCount++;
                std::cout << "Tracker " << t.id << " _lostCount: " << t._lostCount << std::endl;
            }
            if (t._lostCount > 10) {
                auto id = t.id;
                t.cvTracker.release();
                _trackingContexts.erase(_trackingContexts.begin() + i);
                std::cout << "-- Tracker with id: " << id << " (frozen)" << std::endl;
                continue;
            }
            if (t._foundCount > 10 && t._thumbnails.size() > 10) {
                if ((flags & 1) && !t._notified) {
                    t._notified = true;
                    telegram_notify(t._thumbnails);
                }
            }
            RenderDisplacementAndPaths(t, frame, flags);
            if (t._thumbnails.size() > 20) t._thumbnails.clear();
            // keep the last element in trail
            if (t._trail.size() > 20) t._trail.erase(t._trail.begin(), t._trail.end() - 1);
        }
    }

    auto matchDetectionWithTrackingContext(const cv::Rect2d& roi, cv::Mat& mat) {
        for (auto& t : _trackingContexts) {
            auto& last = t._trail.back();
            if (cvl::geometry::doesRectOverlapRect(roi, last)) {
                t._thumbnails.push_back(mat(roi));
                return true;
            }
        }
        return false;
    }

    auto addNewTrackingContext(const cv::Rect2d& roi, const cv::Mat& mat) {
        TrackingContext t;
        t.id = _trackingContexts.size();
        cv::TrackerCSRT::Params params;
        params.psr_threshold = 0.04f; //0.035f;
        //param.template_size = 150;
        //param.admm_iterations = 3;
        t.cvTracker = cv::TrackerCSRT::create(params);
        t._trail.push_back(roi);
        t.cvTracker->init(mat, roi);
        cv::rectangle(mat, roi, cv::Scalar(0, 0, 0 ), 2, 1);  // white
        _trackingContexts.push_back(t);
        std::cout << "++ Tracker with id: " << t.id << std::endl;
    }

    void RenderDisplacementAndPaths(const TrackingContext& t, cv::Mat& mat, int flags) {
            // Displacement
            if (flags & 8) {
                auto first = cvl::geometry::getRectCenter(t._trail.front());
                auto last = cvl::geometry::getRectCenter(t._trail.back());
                cv::line(mat, first, last, cv::Scalar(0, 255, 0), 1);
            }
            // path
            if (flags & 4) {
                for (size_t i = 1; i < t._trail.size() - 1; ++i) {
                    auto&& f = cvl::geometry::getRectCenter(t._trail[i]);
                    auto&& b = cvl::geometry::getRectCenter(t._trail[i-1]);
                    cv::line(mat, f, b, cv::Scalar(0, 0, 255), 1);
                }
            }
            cv::rectangle(mat, t._trail.back(), cv::Scalar(0, 0, 255), 1, 1);
    }

    protected:

    std::vector<TrackingContext> _trackingContexts;
};

} //namespace cvl

#endif //TRACKER_HPP