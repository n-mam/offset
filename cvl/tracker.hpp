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

    int id;
    int _lostCount = 0;
    bool iSkip = false;
    cv::Rect2d *_matched = nullptr;
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
        for (auto& tc : _trackingContexts) {
            saveAndPurgeTrackingContext(tc);
        }
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
        for (auto& pc : iPurgedContexts) {
            auto&& first = cvl::geometry::getRectCenter(pc._trail.front());
            auto&& last = cvl::geometry::getRectCenter(pc._trail.back());
            cv::line(m, first, last, cv::Scalar(0, 255, 255), 1);
        }
        //if (isTest) iCounter->DisplayRefLineAndCounts(m);
    }

    virtual void MatchDetectionWithTrackingContext(Detections& detections, cv::Mat& mat) {
        for (auto& t : _trackingContexts) {
            t._matched = nullptr;
            auto& last = t._trail.back();
            for (auto& roi : detections) {
                if (cvl::geometry::doesRectOverlapRect(roi, last)) {
                    t._matched = &roi;
                }
            }
            if (t._matched) {
                t._thumbnails.emplace_back(mat(*(t._matched)).clone());
            }
        }
        for (auto& t : _trackingContexts) {
            if (t._matched) {
                // mark detection on the original frame as blue
                cv::rectangle(mat, *(t._matched), cv::Scalar(255, 0, 0 ), 1, 1);
            } else {
                t._lostCount++;
            }
        }
    }

    virtual TrackingContext * AddNewTrackingContext(const cv::Mat& m, cv::Rect2d& roi) {
        for (const auto& tc : _trackingContexts){
            // reject the roi if it overlaps with any of the tc
            if ((roi & tc._trail.back()).area()) return nullptr;
        }
        TrackingContext tc;
        tc.id = iCount++;
        cv::TrackerCSRT::Params params;
        params.psr_threshold = 0.04f; //0.035f;
        //param.template_size = 150;
        //param.admm_iterations = 3;
        tc.cvTracker = cv::TrackerCSRT::create(params);
        tc._trail.push_back(roi);
        tc.cvTracker->init(m, roi);
        cv::rectangle(m, roi, cv::Scalar(0, 0, 0 ), 2, 1);  // white
        _trackingContexts.push_back(tc);
        return &(_trackingContexts.back());
    }

    auto updateTrackingContexts(cv::Mat& frame) {
        std::vector<cv::Rect2d> out;
        if (!_trackingContexts.size()) return out;
        for (size_t i = _trackingContexts.size() - 1; i >= 0; i--) {
            auto& tc = _trackingContexts[i];
            if (tc._lostCount > 10) {
                saveAndPurgeTrackingContext(tc);
                _trackingContexts.erase(_trackingContexts.begin() + i);
                std::cout << "Removed frozen tc";
                continue;
            }
            cv::Rect bb;
            bool rc = tc.cvTracker->update(frame, bb);
            if (rc) {
                if (cvl::geometry::isRectInsideMat(bb, frame)) {
                    tc._trail.push_back(bb);
                    out.push_back(bb);
                    if (!tc.iSkip) {
                        //tc.iSkip = iCounter->ProcessTrail(tc._trail, frame);
                    }
                } else {
                    std::cout << "Tracker " << tc.id << " out of the bound, trail size : " << tc._trail.size();
                    saveAndPurgeTrackingContext(tc);
                    _trackingContexts.erase(_trackingContexts.begin() + i);
                }
            } else {
                saveAndPurgeTrackingContext(tc);
                _trackingContexts.erase(_trackingContexts.begin() + i);
                std::cout << "Tracker " << tc.id << " lost, trail size : " << tc._trail.size();
            }
        }
        return out;
    }

    protected:

    size_t iCount = 0;
    //SPCCounter iCounter;
    std::vector<TrackingContext> _trackingContexts;
    std::vector<TrackingContext> iPurgedContexts;

    virtual void saveAndPurgeTrackingContext(TrackingContext& tc) {
        //OnEvent(std::ref(tc));
        if (iPurgedContexts.size() > 5) {
            iPurgedContexts.clear();
            std::cout << "clearing iPurgedContexts...";
        }
        iPurgedContexts.push_back(tc);
    }
};

} //namespace cvl

#endif //TRACKER_HPP