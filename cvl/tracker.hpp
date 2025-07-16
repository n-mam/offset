#ifndef TRACKER_HPP
#define TRACKER_HPP

#include <thread>
#include <vector>
#include <functional>

#include <geometry.hpp>
#include <detector.hpp>

#include <opencv2/opencv.hpp>
#include <opencv2/tracking/tracking.hpp>
#include <curl/curl.h>

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

    auto updateTrackingContexts(cv::Mat& frame) {
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
            if (t._foundCount > 5 && t._thumbnails.size() > 10 && !t._notified) {
                notify_callback(t._thumbnails);
                t._notified = true;
            }
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

    void RenderDisplacementAndPaths(cv::Mat& m, bool isTest = true) {
        for (auto& t : _trackingContexts) {
            // Displacement
            auto first = cvl::geometry::getRectCenter(t._trail.front());
            auto last = cvl::geometry::getRectCenter(t._trail.back());
            cv::line(m, first, last, cv::Scalar(0, 0, 255), 1);
            // path
            for (size_t i = 1; i < t._trail.size() - 1; ++i)
            {
                auto&& f = cvl::geometry::getRectCenter(t._trail[i]);
                auto&& b = cvl::geometry::getRectCenter(t._trail[i-1]);
                cv::line(m, f, b, cv::Scalar(0, 255, 0), 1);
            }
            auto& bb = t._trail.back();
            cv::rectangle(m, bb, cv::Scalar(0, 0, 255), 1, 1);
        }
    }

    void send_telegram_message(const std::string& bot_token, const std::string& chat_id, const std::string& message) {
        CURL* curl = curl_easy_init();
        if(curl) {
            std::string url = "https://api.telegram.org/bot" + bot_token + "/sendMessage";
            std::string post_fields = "chat_id=" + chat_id + "&text=" + curl_easy_escape(curl, message.c_str(), 0);
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_fields.c_str());
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L); // set to 0 for testing only
            CURLcode res = curl_easy_perform(curl);
            if(res != CURLE_OK)
                fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            curl_easy_cleanup(curl);
        }
    }

    void send_telegram_photos(const std::string& bot_token, const std::string& chat_id, const std::vector<std::string>& image_paths) {
        CURL* curl = curl_easy_init();
        if (!curl) return;
        std::string url = "https://api.telegram.org/bot" + bot_token + "/sendMediaGroup";
        // Build JSON media array
        std::string media = "[";
        for (size_t i = 0; i < image_paths.size(); ++i) {
            if (i > 0) media += ",";
            std::string filename = "photo" + std::to_string(i) + ".jpg";
            media += "{\"type\":\"photo\",\"media\":\"attach://" + filename + "\",\"caption\":\"Image " + std::to_string(i+1) + "\"}";
        }
        media += "]";
        curl_mime* mime = curl_mime_init(curl);
        // Add chat_id
        curl_mimepart* part = curl_mime_addpart(mime);
        curl_mime_name(part, "chat_id");
        curl_mime_data(part, chat_id.c_str(), CURL_ZERO_TERMINATED);
        // Add media JSON
        part = curl_mime_addpart(mime);
        curl_mime_name(part, "media");
        curl_mime_data(part, media.c_str(), CURL_ZERO_TERMINATED);
        // Add each image
        for (size_t i = 0; i < image_paths.size(); ++i) {
            part = curl_mime_addpart(mime);
            curl_mime_name(part, ("photo" + std::to_string(i) + ".jpg").c_str());
            curl_mime_filedata(part, image_paths[i].c_str());
        }
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_MIMEPOST, mime);
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            std::cerr << "curl error: " << curl_easy_strerror(res) << std::endl;
        }
        curl_mime_free(mime);
        curl_easy_cleanup(curl);
    }

    void notify_callback(const std::vector<cv::Mat>& thumbnails) {
        std::cout << "notify_callback" << std::endl;
        std::vector<std::pair<int, double>> lv_scores;
        for (int i = 0; i < thumbnails.size(); i++) {
            lv_scores.push_back({i, cvl::geometry::computeLaplacianVariance(thumbnails[i])});
        }
        std::ranges::sort(lv_scores, [](auto& e1, auto& e2){ return e1.second < e2.second; });
        for (const auto& e : lv_scores) {
            std::cout << e.first << ": " << e.second << std::endl;
        }
        std::vector<std::string> paths;
        int idx = lv_scores[lv_scores.size() - 1].first;
        std::string path = "./thumb_" + std::to_string(idx) + ".jpg";
        cv::imwrite(path, thumbnails[idx]);
        paths.push_back(path);
        std::thread([this, paths]() {
            std::string chat_id = "1799980801";
            std::string message = "Face Detection Alert";
            std::string bot_token = "xxxx";
            send_telegram_message(bot_token, chat_id, message);
            send_telegram_photos(bot_token, chat_id, paths);
        }).detach();
    }

    protected:

    std::vector<TrackingContext> _trackingContexts;
};

} //namespace cvl

#endif //TRACKER_HPP