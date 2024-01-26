#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {

}

CompareManager::~CompareManager() {

}

void CompareManager::setCompareFileModel(CompareFileModel *model) {
    _file_models.push_back(model);
}

template<typename T>
void CompareManager::makeEqual(T& A, T& B) {
    auto delta = std::abs(
        static_cast<int>(A.size() - B.size()));
    if (delta) {
        if (A.size() > B.size()) {
            B.insert(B.end(), delta, {0, "", {0, 0}});
        } else if (A.size() < B.size()) {
            A.insert(A.end(), delta, {0, "", {0, 0}});
        }
    }
}

template<typename T>
auto CompareManager::finalizeDisplayAttributes(T& A, T& B) {
    auto n = std::min(A.size(), B.size());
    auto x = std::max(A.size(), B.size());
    for (auto i = 0; i < n; i++) {
        if (A[i].e_hash != B[i].e_hash) {
            if (!A[i]._real() && B[i]._real()) {
                B[i]._set_added();
            } else if (A[i]._real() && !B[i]._real()) {
                A[i]._set_full();
            } else {
                A[i]._set_full();
                B[i]._set_full();
            }
        }
    }
    if (A.size() != B.size()) {
        for (auto i = n; i < x; i++) {
            if (A.size() > B.size()) {
                A[i]._set_full();
            } else {
                B[i]._set_added();
            }
        }
    }
}

template <typename T>
auto CompareManager::getHashVectorsFromModels(const T& A, const T& B) {
    std::vector<size_t> ha;
    std::vector<size_t> hb;
    ha.reserve(A.size());
    hb.reserve(B.size());
    for (const auto& e : A) {
        ha.push_back(e.e_hash);
    }
    for (const auto& e : B) {
        hb.push_back(e.e_hash);
    }
    return std::make_pair(ha, hb);
}

template<typename T>
auto CompareManager::get_lcs_pos_vector(const T& lcs, const T& ha, const T& hb) {
    bool aligned = true;
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
        auto n = std::min(lsp.pos_in_a.size(), lsp.pos_in_b.size());
        for (auto i = 0; i < n; i ++) {
            if (lsp.pos_in_a[i] != lsp.pos_in_b[i]) {
                aligned = false;
                break;
            }
        }
    }
    return std::make_pair(lcs_pos, aligned);
}

template<typename T>
auto CompareManager::processDiffSections(T& A, T& B) {
    // all unique and common LCS symbols have been aligned at this point
    // Loop through models and find diff sections between aligned symbols
    int i = 0;
    int j = 0;

    for (auto k = 0; k < std::min(A.size(), B.size()); k++) {
        if (A[k].e_hash == B[k].e_hash) {
            if (j - i > 1) {
                processSection(A, B, i, j);
            }
            i = j = k + 1;
        } else {
            j++;
        }
    }

    if (j - i > 1) {
        processSection(A, B, i, j);
    }
}

template<typename T>
auto CompareManager::processSection(T& A, T&B, int i, int j) {
    
    LOG << "diff section at " << i + 1 << "," << j + 1;

    //Constructs the container with the contents of the range [first, last)
    std::vector<CompareFileModel::Element> sub_a(A.begin() + i, A.begin() + j);
    std::vector<CompareFileModel::Element> sub_b(B.begin() + i, B.begin() + j);

    // sections are equal before this comparision
    compareRoot(sub_a, sub_b);

    // make sections equal again after comparision
    auto delta = std::abs(
        static_cast<int>(sub_a.size() - sub_b.size()));

    if (sub_a.size() > sub_b.size()) {
        sub_b.insert(sub_b.end(), delta, {});
    } else if (sub_a.size() < sub_b.size()) {
        sub_a.insert(sub_a.end(), delta, {});
    }

    // clear the original sub_b window in B
    B.erase(B.begin() + i, B.begin() + j);
    // clear the original sub_a window in A
    A.erase(A.begin() + i, A.begin() + j);

    // insert sub_b at the starting of the cleared area
    B.insert(B.begin() + i, sub_b.begin(), sub_b.end());
    // insert sub_a at the starting of the cleared area
    A.insert(A.begin() + i, sub_a.begin(), sub_a.end());

    // scan max(sub_a, sub_b) sized section of
    // A and B for duplicate inserted empty rows
    for (auto m = 0; m < std::max(sub_a.size(), sub_b.size()); m++) {
        if (!A[i + m]._real() && !B[i + m]._real()) {
            A.erase(A.begin() + i + m);
            B.erase(B.begin() + i + m);
        }
    }
}

template<typename T>
auto CompareManager::align(T& A, T&B, std::vector<_lcs_sym_pos>& lcs_pos, int n) {
    uint32_t n_aligned = 0;
    uint32_t added_in_a = 0;
    uint32_t added_in_b = 0;
    for (auto& p : lcs_pos) {
        auto& _in_a = p.pos_in_a;
        auto& _in_b = p.pos_in_b;
        if ((_in_a.size() <= n) && (_in_b.size() <= n)) {
            auto in_a = _in_a[0];
            auto in_b = _in_b[0];
            in_a += added_in_a;
            in_b += added_in_b;
            auto n = std::abs(in_a - in_b);
            if (in_a < in_b) {
                A.insert(A.begin() + in_a, n, {0, "", {0, 0}});
                added_in_a += n;
            } else if (in_b < in_a) {
                B.insert(B.begin() + in_b, n, {0, "", {0, 0}});
                added_in_b += n;
            } else if (in_a == in_b) {
                n_aligned++;
            }
            for (auto& q : lcs_pos) {
                if ((&p != &q) && (p.e == q.e)) {
                    q.pos_in_a.erase(q.pos_in_a.begin());
                    q.pos_in_b.erase(q.pos_in_b.begin());
                }
            }
        } else {
            continue;
        }
    }
    return std::make_tuple(added_in_a, added_in_b, n_aligned);
}

template<typename T>
auto CompareManager::compareRoot(T& A, T&B) {

    auto [ha, hb] = getHashVectorsFromModels(A, B);

    auto r = osl::find_lcs<std::vector<size_t>>(ha, hb);

    if (!r.ss.size()) {
        makeEqual(A, B);
        finalizeDisplayAttributes(A, B);
        return r.ss.size();
    }

    // use the first for now
    auto& lcs = r.ss[0];

    // vector of all lcs symbol positions in A and B
    auto [lcs_pos, fully_aligned] = get_lcs_pos_vector(lcs, ha, hb);

    // loop through all lcs hashes and adjust models A
    // and B to align unique symbols. skip duplicates
    if (!fully_aligned) {
        auto n = 1;
        while (true) {
            auto [added_in_a, added_in_b, n_aligned] = align(A, B, lcs_pos, n++);
            if (added_in_a || added_in_b || n_aligned) break;
        }
    }

    // make sure the 2 modified models are of same size
    // else rows of one would be squished more than the other
    makeEqual(A, B);
    processDiffSections(A, B);
    finalizeDisplayAttributes(A, B);
    return lcs.size();
}

template<typename T>
auto CompareManager::compareGranular(T& A, T&B) {
    // for all diff items, run lcs at a lower granular level
    for (auto i = 0; i < std::min(A.size(), B.size()); i++) {
        if (A[i].e_hash != B[i].e_hash) {
            auto& la = A[i].e_text;
            auto& lb = B[i].e_text;
            if (la.size() && lb.size()) {
                std::vector<CompareFileModel::Element> CA;
                std::vector<CompareFileModel::Element> CB;
                for (auto& c : la) {
                    CA.push_back({std::hash<unsigned char>{}(c), {c}, {1, 0}});
                }
                for (auto& c : lb) {
                    CB.push_back({std::hash<unsigned char>{}(c), {c}, {1, 0}});
                }
                auto l = compareRoot(CA, CB);
                if (l) {
                    A[i].e_child = std::move(CA);
                    B[i].e_child = std::move(CB);
                }
            }
        }
    }
}

template<typename T>
auto CompareManager::resetToInitialState(T& A) {
    for (auto it = A.begin(); it != A.end(); ) {
        auto& e = *it;
        if (!e._real()) {
            it = A.erase(it);
        } else {
            e.e_flags._indent = 0;
            e.e_flags._diff_full = 0;
            e.e_flags._diff_part = 0;
            e.e_flags._diff_added = 0;
            it++;
        }
    }
}

size_t CompareManager::compare() {
    _file_models[0]->beginResetModel();
    _file_models[1]->beginResetModel();
    auto& A = _file_models[0]->_model;
    auto& B = _file_models[1]->_model;
    resetToInitialState(A);
    resetToInitialState(B);
    auto l = compareRoot(A, B);
    compareGranular(A, B);
    _file_models[1]->endResetModel();
    _file_models[0]->endResetModel();
    return l;
}

// std::string q = "GAC";
// std::string p = "AGCAT";
// auto results = osl::find_lcs<std::string>(p, q);
// for (const auto& result : results.ss) {
//     result;
// }