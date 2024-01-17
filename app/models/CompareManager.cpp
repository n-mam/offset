#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {

}

CompareManager::~CompareManager() {

}

void CompareManager::setCompareFileModel(CompareFileModel *model) {
    _models.push_back(model);
}

void CompareManager::onFileModelChanged(CompareFileModel *model) {
    for (auto& m : _models) {
        if (m != model) {
            m->resetToOriginalState();
        }
    }
}

// compute median of all lcs symbol positions in A and B
auto CompareManager::computeMedian(const std::unordered_map<size_t, _lcs_sym_pos>& lcs_pos_map) {

    int median_a, median_b;
    std::vector<int> all_pos_a;
    std::vector<int> all_pos_b;

    for (const auto& [e, sp] : lcs_pos_map) {
        all_pos_a.insert(all_pos_a.end(), sp.pos_in_a.begin(), sp.pos_in_a.end());
        all_pos_b.insert(all_pos_b.end(), sp.pos_in_b.begin(), sp.pos_in_b.end());
    }

    std::sort(all_pos_a.begin(), all_pos_a.end());
    std::sort(all_pos_b.begin(), all_pos_b.end());

    if (all_pos_a.size() % 2) {
        median_a = (all_pos_a[all_pos_a.size()/2] + all_pos_a[(all_pos_a.size()/2) + 1]) / 2;
    } else {
        median_a = all_pos_a[all_pos_a.size()/2];
    }

    if (all_pos_b.size() % 2) {
        median_b = (all_pos_b[all_pos_b.size()/2] + all_pos_b[(all_pos_b.size()/2) + 1]) / 2;
    } else {
        median_b = all_pos_b[all_pos_b.size()/2];
    }

    return std::make_pair(median_a, median_b);
}

void CompareManager::pickNearestToMedian(std::vector<int>& vec, int median) {
    int32_t nearest = -1;
    int32_t diff = INT32_MAX;
    for (const auto& pos : vec) {
        if (std::abs(median - pos) < diff) {
            nearest = pos;
            diff = std::abs(median - pos);
        }
    }
    vec.clear();
    vec.push_back(nearest);
}

void CompareManager::compare() {

    auto& A = _models[0]->_model;
    auto& B = _models[1]->_model;

    std::vector<size_t> ha;
    std::vector<size_t> hb;

    ha.reserve(A.size());
    ha.reserve(B.size());

    for (const auto& e : A) {
        ha.push_back(e.li_hash);
    }
    for (const auto& e : B) {
        hb.push_back(e.li_hash);
    }

    auto results = osl::find_lcs<std::vector<size_t>>(ha, hb);

    if (!results.ss.size()) return;

    // use the first for now
    auto& lcs = results.ss[0];

    // map of lcs hashes to their 
    // positions in the 2 strings
    std::unordered_map<size_t, _lcs_sym_pos> lcs_pos_map;
    lcs_pos_map.reserve(lcs.size());

    for (const auto& e : lcs) {
        _lcs_sym_pos sp;
        for (auto it = ha.begin(); it != ha.end(); it++) {
            if (e == *it) {
                sp.pos_in_a.push_back(std::distance(ha.begin(), it));
            }
        }
        for (auto it = hb.begin(); it != hb.end(); it++) {
            if (e == *it) {
                sp.pos_in_b.push_back(std::distance(hb.begin(), it));
            }          
        }
        lcs_pos_map.insert({e, sp});
    }

    auto [median_a, median_b] = computeMedian(lcs_pos_map);

    // loop through all unmatched _lcs_sym_pos entries 
    // and match lcs symbols from A to B by picking 
    // the one that is at a min distance to any of the 
    // other. Remove only those matched entries from lcs_pos_map
    std::unordered_map<size_t, _lcs_sym_pos_matched> lcs_pos_map_matched;
    lcs_pos_map_matched.reserve(lcs.size());
    for (auto& e : lcs) {
        auto& sp = lcs_pos_map.find(e)->second;
        auto la = sp.pos_in_a.size();
        auto lb = sp.pos_in_b.size();
        if (la > 1 || lb > 1) {
            for (auto i = 0; i < std::min(la, lb); i++) {
                auto& bigger = (la > lb) ? sp.pos_in_a : sp.pos_in_b;
                auto& smaller = (la <= lb) ? sp.pos_in_a : sp.pos_in_b;
                int match_big = -1;
                int diff = INT32_MAX;
                // match pos in smaller with all pos in bigger (min dist)
                for (auto& pos_big : bigger) {
                    if (std::abs(smaller[i] - pos_big) < diff) {
                        diff = std::abs(smaller[i] - pos_big);
                        match_big = pos_big;
                    }
                }
                // add the match pair to lcs_pos_map_matched
                if (la > lb) { // A is bigger or equal
                    lcs_pos_map_matched.insert({e, {match_big, smaller[i]}});
                } else { // B is bigger
                    lcs_pos_map_matched.insert({e, {smaller[i], match_big}});
                }
            }
        } else {
            lcs_pos_map_matched.insert({e, {sp.pos_in_a[0], sp.pos_in_b[0]}});
        }
    }

    // At this point the lcs symbols in A and B should
    // be aligned and have a one-to-one mapping. Loop
    // through all lcs result hashes and adjust models
    // A and B. Then loop through all model elements
    // and change their display attributes   
    auto n_total_added_in_a = 0;
    auto n_total_added_in_b = 0;
    for (const auto& e : lcs) {
        auto [in_a, in_b] = lcs_pos_map_matched.find(e)->second;
        in_a += n_total_added_in_a;
        in_b += n_total_added_in_b;
        auto n = std::abs(in_a - in_b);
        if (in_a < in_b) {
            _models[0]->insertStripedRows(in_a, n);
            n_total_added_in_a += n;
        } else if (in_b < in_a) {
            _models[1]->insertStripedRows(in_b, n);
            n_total_added_in_b += n;
        }
    }

    auto n = std::min(A.size(), B.size());
    auto x = std::max(A.size(), B.size());

    _models[0]->beginResetModel();
    _models[1]->beginResetModel();

    for (auto i = 0; i < n; i++) {
        if (A[i].li_hash != B[i].li_hash) {
            A[i].li_bgcolor = B[i].li_bgcolor = "#701414";
        }
    }

    if (A.size() != B.size()) {
        for (auto i = n; i < x; i++) {
            if (A.size() > B.size()) {
                A[i].li_bgcolor = "#4C5A2C";
            } else {
                B[i].li_bgcolor = "#4C5A2C";
            }
        }
    }

    _models[1]->endResetModel();
    _models[0]->endResetModel();
}

// std::string q = "GAC";
// std::string p = "AGCAT";
// auto results = osl::find_lcs<std::string>(p, q);
// for (const auto& result : results.ss) {
//     result;
// }