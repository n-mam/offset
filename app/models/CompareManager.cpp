#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {

}

CompareManager::~CompareManager() {

}

void CompareManager::setCompareFileModel(CompareFileModel *model) {
    _file_models.push_back(model);
}

void CompareManager::onFileModelChanged(CompareFileModel *model) {
    for (auto& fm : _file_models) {
        if (fm != model) {
            fm->resetToOriginalState();
        }
    }
}

template<typename T>
auto CompareManager::finalizeDisplayAttributes(T& A, T& B) {
    auto n = std::min(A.size(), B.size());
    auto x = std::max(A.size(), B.size());
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
}

template <typename T>
auto CompareManager::getHashVectorsFromModels(const T& a, const T& b) {
    std::vector<size_t> ha;
    std::vector<size_t> hb;
    ha.reserve(a.size());
    hb.reserve(b.size());
    for (const auto& e : a) {
        ha.push_back(e.li_hash);
    }
    for (const auto& e : b) {
        hb.push_back(e.li_hash);
    }
    return std::make_pair(ha, hb);
}

template<typename T>
auto CompareManager::get_lcs_pos_vector(const T& lcs, const T& ha, const T& hb) {
    std::vector<_lcs_sym_pos> lcs_pos;
    lcs_pos.reserve(lcs.size());
    for (const auto& e : lcs) {
        _lcs_sym_pos lsp = {e};
        for (auto it = ha.begin(); it != ha.end(); it++) {
            if (e == *it) {
                lsp.pos_in_a.push_back(std::distance(ha.begin(), it));
            }
        }
        for (auto it = hb.begin(); it != hb.end(); it++) {
            if (e == *it) {
                lsp.pos_in_b.push_back(std::distance(hb.begin(), it));
            }
        }
        lcs_pos.push_back(lsp);
    }
    return lcs_pos;
}

template<typename T>
auto CompareManager::compareInternal(T& A, T&B) {

    auto [ha, hb] = getHashVectorsFromModels(A, B);

    auto r = osl::find_lcs<std::vector<size_t>>(ha, hb);

    if (!r.ss.size()) return r.ss.size();

    // use the first for now
    auto& lcs = r.ss[0];

    // vector of lcs symbol hashes  
    // to their positions in A and B
    auto lcs_pos = get_lcs_pos_vector(lcs, ha, hb);

    // At this point the lcs symbols in A and B should
    // be aligned and have a one-to-one mapping. Loop
    // through all lcs hashes and adjust models
    // A and B. skip duplicated lcs symbols
    auto n_total_added_in_a = 0;
    auto n_total_added_in_b = 0;
    for (const auto& e : lcs_pos) {
        auto& _in_a = e.pos_in_a;
        auto& _in_b = e.pos_in_b;
        if (_in_a.size() > 1) continue;
        for (auto i = 0; i < _in_a.size(); i++) {
            auto in_a = _in_a[i];
            auto in_b = _in_b[i];
            in_a += n_total_added_in_a;
            in_b += n_total_added_in_b;
            auto n = std::abs(in_a - in_b);
            if (in_a < in_b) {
                A.insert(A.begin() + in_a, n, {});
                n_total_added_in_a += n;
            } else if (in_b < in_a) {
                B.insert(B.begin() + in_b, n, {});
                n_total_added_in_b += n;
            }
        }
    }

    // all unique and common LCS symbols 
    // have been aligned at this point
    // Loop through both models and find 
    // sections in between aligned symbols

    int i = 0;
    int j = -1;

    for (auto k = 0; k < std::min(A.size(), B.size()); k++) {
        j++;
        if (A[k].li_hash == B[k].li_hash) {
            if (j - 1 - i) {
                LOG << "section detected at " << i + 1 << "," << j;
                std::vector<CompareFileModel::LineItem> sub_a(A.begin() + i, A.begin() + j);
                std::vector<CompareFileModel::LineItem> sub_b(B.begin() + i, B.begin() + j);
                compareInternal(sub_a, sub_b);
                auto delta = std::abs(static_cast<int>(sub_a.size() - sub_b.size()));
                if (delta) {
                    if (sub_b.size() > sub_a.size()) {
                        // clear the original sub_b window in B
                        B.erase(B.begin() + i, B.begin() + j);
                        // insert sub_b at the starting of the cleared area
                        B.insert(B.begin() + i, sub_b.begin(), sub_b.end());
                        // insert delta rows in A to preserve the rest of earlier alingment
                        A.insert(A.begin() + j, delta, {});
                    } else if (sub_a.size() > sub_b.size()) {
                        // clear the original sub_a window in A
                        A.erase(A.begin() + i, A.begin() + j);
                        // insert sub_a at the starting of the cleared area
                        A.insert(A.begin() + i, sub_a.begin(), sub_a.end());
                        // insert delta rows in B to preserve the rest of earlier alingment
                        B.insert(B.begin() + j, delta, {});
                    } else if (sub_a.size() == sub_b.size()) {
                        assert(false);
                    }
                    // scan max(sub_s, sub_b) sized section of
                    // A and B for duplicate inserted empty rows
                    for (auto m = 0; m < std::max(sub_a.size(), sub_b.size()); m++) {
                        if (!A[i + m].li_real && !B[i + m].li_real) {
                            A.erase(A.begin() + i + m);
                            B.erase(B.begin() + i + m);
                        }
                    }
                }
            }
            j = k;
            i = k + 1;
        }
    }

    finalizeDisplayAttributes(A, B);

    return lcs.size();
}

size_t CompareManager::compare() {
    auto& A = _file_models[0]->_model;
    auto& B = _file_models[1]->_model;
    _file_models[0]->beginResetModel();
    _file_models[1]->beginResetModel();
    auto lcs_len = compareInternal(A, B);
    // make sure the final 2 modified models are of same size
    // else rows of one would be squished more than the other
    auto delta = std::abs(
        static_cast<int>(A.size() - B.size()));
    if (A.size() > B.size()) {
        B.insert(B.end(), delta, {});
    } else if (A.size() < B.size()) {
        A.insert(A.end(), delta, {});
    }
    _file_models[1]->endResetModel();
    _file_models[0]->endResetModel();
    return lcs_len;
}

// std::string q = "GAC";
// std::string p = "AGCAT";
// auto results = osl::find_lcs<std::string>(p, q);
// for (const auto& result : results.ss) {
//     result;
// }