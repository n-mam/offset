#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {

}

CompareManager::~CompareManager() {

}

void CompareManager::setCompareFileModel(CompareFileModel *model) {
    m_models.push_back(model);
    if (m_models.size() == 2) {
        compare();
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

    auto& A = m_models[0]->m_model;
    auto& B = m_models[1]->m_model;

    std::vector<size_t> ha;
    std::vector<size_t> hb;

    for (const auto& e : A) {
        ha.push_back(e.li_hash);
    }
    for (const auto& e : B) {
        hb.push_back(e.li_hash);
    }

    auto results = osl::find_lcs<std::vector<size_t>>(ha, hb);

    if (!results.ss.size()) return;

    // use the first for now
    auto lcs = results.ss[0];

    // map of lcs hashes to their 
    // positions in the 2 strings
    std::unordered_map<size_t, _lcs_sym_pos> lcs_pos_map;

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

    // loop through all _lcs_sym_pos entries and 
    // remove duplicate lcs symbols from A and B
    // by picking the one nearest to the median
    for (auto& [e, sp] : lcs_pos_map) {
        if (sp.pos_in_a.size() > 1) {
            pickNearestToMedian(sp.pos_in_a, median_a);
        }
        if (sp.pos_in_b.size() > 1) {
            pickNearestToMedian(sp.pos_in_b, median_b);
        }
    }

    // At this point the lcs symbols in A and B should
    // be aligned and have a one-to-one mapping. Loop
    // through all lcs result hashes and adjust models
    // A and B. Then loop through all model elements
    // and change their display attributes
    m_models[0]->beginResetModel();
    m_models[1]->beginResetModel();
    
    auto n_total_added_in_a = 0;
    auto n_total_added_in_b = 0;
    for (auto& [e, sp] : lcs_pos_map) {
        auto in_a = sp.pos_in_a[0] + n_total_added_in_a;
        auto in_b = sp.pos_in_b[0] + n_total_added_in_b;
        auto n = std::abs(in_a - in_b);
        if (in_a < in_b) {
            A.insert(A.begin() + in_a, n, {});
            n_total_added_in_a += n;
        } else if (in_b < in_a) {
            B.insert(B.begin() + in_b, n, {});
            n_total_added_in_b += n;
        }
    }

    auto n = std::min(A.size(), B.size());
    auto x = std::max(A.size(), B.size());

    for (auto i = 0; i < n; i++) {
        if (A[i].li_hash != B[i].li_hash) {
            A[i].li_bgcolor = B[i].li_bgcolor = "#701414";
        }
    }

    if (A.size() != B.size()) {
        for (auto i = n; i < x; i++) {
            if (A.size() > B.size()){
                A[i].li_bgcolor = "#4C5A2C";
            } else {
                B[i].li_bgcolor = "#4C5A2C";
            }
        }
    }

    m_models[0]->endResetModel();
    m_models[1]->endResetModel();
}

// std::string q = "GAC";
// std::string p = "AGCAT";
// auto results = osl::find_lcs<std::string>(p, q);
// for (const auto& result : results.ss) {
//     result;
// }