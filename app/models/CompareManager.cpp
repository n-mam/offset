#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {

}

CompareManager::~CompareManager() {

}

void CompareManager::onFileModelChanged(CompareFileModel *model) {
    currentDiffIndex = -1;
    comparisionDone = false;
}

size_t CompareManager::getNextDiffIndex() {
    if (comparisionDone) {
        auto& A = _file_models[0]->_model;
        auto& B = _file_models[1]->_model;
        assert(A.size() == B.size());
        auto old = currentDiffIndex;
        for (auto i = currentDiffIndex + 1; i < static_cast<int64_t>(A.size()); i++) {
            if (A[i].e_hash != B[i].e_hash) {
                currentDiffIndex = i;
                break;
            }
        }
        if (currentDiffIndex == old) {
            currentDiffIndex = -1;
            return getNextDiffIndex();
        }
    }
    return currentDiffIndex;
}
size_t CompareManager::getPrevDiffIndex() {
    if (comparisionDone) {
        auto& A = _file_models[0]->_model;
        auto& B = _file_models[1]->_model;
        assert(A.size() == B.size());
        auto old = currentDiffIndex;
        for (auto i = currentDiffIndex - 1; i >= 0; i--) {
            if (A[i].e_hash != B[i].e_hash) {
                currentDiffIndex = i;
                break;
            }
        }
        if (currentDiffIndex == old) {
            currentDiffIndex = A.size();
            return getPrevDiffIndex();
        }
    }
    return currentDiffIndex;
}

void CompareManager::setCompareFileModel(CompareFileModel *model) {
    _file_models.push_back(model);
}

template<typename T>
auto CompareManager::dumpModels(const T& A, const T&B, const std::string& ctx) {
    std::stringstream ss_a;
    std::stringstream ss_b;
    for (const auto& e : A)
        ss_a << e.e_text << ",";
    for (const auto& e : B)
        ss_b << e.e_text << ",";
    auto s_a = ss_a.str();
    auto s_b = ss_b.str();
    s_a.pop_back();
    s_b.pop_back();
    LOG << "[" << s_a << "] " << ctx;
    LOG << "[" << s_b << "] " << ctx;
}

template<typename T>
auto CompareManager::makeEqual(T& A, T& B) {
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
auto CompareManager::removeNotRealPairs(T& A, T&B) {
    makeEqual(A, B);
    while (true) {
        bool done = true;
        for (auto i = 0; i < A.size(); i++) {
            if (!A[i]._real() && !B[i]._real()) {
                done = false;
                A.erase(A.begin() + i);
                B.erase(B.begin() + i);
            }
        }
        if (done) break;
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
auto CompareManager::getLcsPosVector(const T& lcs, const T& ha, const T& hb) {
    bool aligned = true;
    std::vector<_sym_pos> lcs_pos;
    lcs_pos.reserve(lcs.size());
    for (const auto& e : lcs) {
        _sym_pos lsp = {e};
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
auto CompareManager::getUniqueCommonPosVector(T& A, T&B) {
    // frequency map
    std::unordered_map<size_t, int> ua_map;
    std::unordered_map<size_t, int> ub_map;

    for (const auto& e : A) {
        ua_map[e] += 1;
    }
    for (const auto& e : B) {
        ub_map[e] += 1;
    }

    for (auto it = ua_map.begin(); it != ua_map.end(); ) {
        auto [e, n] = *it;
        if (n > 1) {
            it = ua_map.erase(it);
        } else {
            it++;
        }
    }
    for (auto it = ub_map.begin(); it != ub_map.end(); ) {
        auto [e, n] = *it;
        if (n > 1) {
            it = ub_map.erase(it);
        } else {
            it++;
        }
    }

    auto& large = A.size() > B.size() ? A : B;
    auto& small = A.size() <= B.size() ? A : B;

    std::vector<_sym_pos> uc_pos;
    uc_pos.reserve(small.size());
    for (auto i = 0; i < small.size(); i++) {
        auto& e = small[i];
        _sym_pos sp = {e};
        auto it_a = ua_map.find(e);
        auto it_b = ub_map.find(e);
        if ((it_a != ua_map.end()) && (it_b != ub_map.end())) {
            auto index_in_other = std::find(large.begin(), large.end(), e) - large.begin();
            if (A.size() <= B.size()) { // i is from A
                sp.pos_in_a.push_back(i);
                sp.pos_in_b.push_back(index_in_other);
            } else { // i is from B
                sp.pos_in_a.push_back(index_in_other);
                sp.pos_in_b.push_back(i);
            }
            uc_pos.push_back(sp);
        }
    }

    return uc_pos;
}

template<typename T>
auto CompareManager::processDiffSections(T& A, T& B) {
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

    // range [first, last)
    std::vector<CompareFileModel::Element> sub_a(A.begin() + i, A.begin() + j);
    std::vector<CompareFileModel::Element> sub_b(B.begin() + i, B.begin() + j);

    if ((sub_a.size() == 2) && (sub_b.size() == 2)) {
        if (((sub_a[0]._real() && !sub_a[1]._real()) &&
             (!sub_b[0]._real() && sub_b[1]._real())) ||
            ((!sub_a[0]._real() && sub_a[1]._real()) &&
             (sub_b[0]._real() && !sub_b[1]._real()))) {
                if (!sub_a[0]._real())
                    sub_a[0] = sub_a[1];
                if (!sub_b[0]._real())
                    sub_b[0] = sub_b[1];
                sub_a.erase(sub_a.end() - 1);
                sub_b.erase(sub_b.end() - 1);
            }
    }

    compareRoot(sub_a, sub_b);

    // make sections equal again after comparision
    auto delta = std::abs(
        static_cast<int>(sub_a.size() - sub_b.size()));

    if (sub_a.size() > sub_b.size()) {
        sub_b.insert(sub_b.end(), delta, {});
    } else if (sub_a.size() < sub_b.size()) {
        sub_a.insert(sub_a.end(), delta, {});
    }

    // erase the original sub_b window in B
    B.erase(B.begin() + i, B.begin() + j);
    // erase the original sub_a window in A
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
auto CompareManager::align(T& A, T&B, std::vector<_sym_pos>& pos, int n) {
    uint32_t n_aligned = 0;
    uint32_t added_in_a = 0;
    uint32_t added_in_b = 0;
    for (auto& p : pos) {
        auto& _in_a = p.pos_in_a;
        auto& _in_b = p.pos_in_b;
        if ((_in_a.size() && _in_a.size() <= n) &&
            (_in_a.size() && _in_b.size() <= n)) {
            auto in_a = _in_a[0];
            auto in_b = _in_b[0];
            in_a += added_in_a;
            in_b += added_in_b;
            auto n = std::abs(in_a - in_b);
            auto& ta = A[in_a].e_text; //debug
            auto& tb = B[in_b].e_text; //debug
            if (in_a < in_b) {
                A.insert(A.begin() + in_a, n, {0, "", {0, 0}});
                added_in_a += n;
            } else if (in_b < in_a) {
                B.insert(B.begin() + in_b, n, {0, "", {0, 0}});
                added_in_b += n;
            } else if (in_a == in_b) {
                n_aligned++;
            }
            for (auto& q : pos) {
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
size_t CompareManager::compareRoot(T& A, T&B) {

    auto [ha, hb] = getHashVectorsFromModels(A, B);
    auto uc_pos = getUniqueCommonPosVector(ha, hb);

    if (uc_pos.size()) {
        align(A, B, uc_pos, 1);
        removeNotRealPairs(A, B);
        processDiffSections(A, B);
    } else {
        auto r = osl::find_lcs<std::vector<size_t>>(ha, hb);
        if (!r.ss.size()) {
            makeEqual(A, B);
            finalizeDisplayAttributes(A, B);
            return r.ss.size();
        }

        // use the first for now
        auto& lcs = r.ss[0];
        // vector of all lcs symbol positions in A and B
        auto [lcs_pos, fully_aligned] = getLcsPosVector(lcs, ha, hb);

        // loop through all lcs hashes and adjust models A
        // and B to align unique symbols. skip duplicates
        if (!fully_aligned) {
            auto n = 1;
            while (true) {
                auto [added_in_a, added_in_b, n_aligned] = align(A, B, lcs_pos, n++);
                if (added_in_a || added_in_b || n_aligned) break;
            }
        }
    }

    removeNotRealPairs(A, B);
    finalizeDisplayAttributes(A, B);
    return 1;
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
    comparisionDone = true;
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