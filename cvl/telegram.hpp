#ifndef TELEGRAM_HPP
#define TELEGRAM_HPP

#include <thread>
#include <string>
#include <vector>
#include <iostream>

#include <curl/curl.h>

namespace cvl {

inline void send_telegram_message(const std::string& bot_token, const std::string& chat_id, const std::string& message) {
    CURL* curl = curl_easy_init();
    if (curl) {
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

inline void send_telegram_photos(const std::string& bot_token, const std::string& chat_id, const std::vector<std::string>& image_paths) {
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
        std::cout << "curl error: " << curl_easy_strerror(res) << std::endl;
    }
    curl_mime_free(mime);
    curl_easy_cleanup(curl);
}

inline void telegram_notify(const std::vector<cv::Mat>& thumbnails) {
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
    std::thread([paths]() {
        std::string message = "Face Detection Alert";
        std::vector<std::string> chat_ids = {"1799980801", "7017371705"};
        std::string bot_token = "xxxx";
        for (const auto& chat_id : chat_ids) {
            send_telegram_message(bot_token, chat_id, message);
            send_telegram_photos(bot_token, chat_id, paths);
        }
    }).detach();
}

}

#endif