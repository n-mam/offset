#include <osl/lcs>

#include <CompareManager.h>

CompareManager::CompareManager() {}

CompareManager::~CompareManager() {}

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
    return;
    std::stringstream ss_a;
    std::stringstream ss_b;
    for (const auto& e : A)
        ss_a << (e._real() ? e.e_text : "X") << ",";
    for (const auto& e : B)
        ss_b << (e._real() ? e.e_text : "X") << ",";
    auto s_a = ss_a.str();
    auto s_b = ss_b.str();
    s_a.pop_back();
    s_b.pop_back();
    LOG << "[" << s_a << "] " << ctx;
    LOG << "[" << s_b << "] " << ctx;
}

template<typename T>
auto CompareManager::makeEqual(T& A, T& B) {
    auto d = std::abs(
        static_cast<int>(A.size() - B.size()));
    if (d) {
        if (A.size() > B.size()) {
            B.insert(B.end(), d, {0, "", {0, 0}});
        } else if (A.size() < B.size()) {
            A.insert(A.end(), d, {0, "", {0, 0}});
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
auto CompareManager::getSimplifiedHashVectors(const T& A, const T& B, TRuleFunction fn) {
    std::vector<std::pair<size_t, int>> ha;
    std::vector<std::pair<size_t, int>> hb;
    ha.reserve(A.size());
    hb.reserve(B.size());
    for (auto i = 0; i < A.size(); i++) {
        ha.push_back({std::hash<std::string>{}(fn(A[i].e_text)), i});
    }
    for (auto i = 0; i < B.size(); i++) {
        hb.push_back({std::hash<std::string>{}(fn(B[i].e_text)), i});
    }
    return std::make_pair(ha, hb);
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
auto CompareManager::getUniqueCommonPosVector(const T& A, const T& B) {

    auto& large = A.size() > B.size() ? A : B;
    auto& small = A.size() <= B.size() ? A : B;

    std::vector<std::unordered_map<size_t, int>> ua_maps(_rules.size());
    std::vector<std::unordered_map<size_t, int>> ub_maps(_rules.size());
    std::vector<std::unordered_map<std::string, int>> lp_maps(_rules.size());

    for (auto i = 0; i < _rules.size(); i++) {
        ua_maps[i].reserve(A.size());
        ub_maps[i].reserve(B.size());
        auto [ha, hb] = getSimplifiedHashVectors(A, B, _rules[i]);
        for (const auto& [e, idx] : ha) {
            ua_maps[i][e] += 1;
        }
        for (const auto& [e, idx] : hb) {
            ub_maps[i][e] += 1;
        }
        for (auto it = ua_maps[i].begin(); it != ua_maps[i].end(); ) {
            auto [e, n] = *it;
            if (n > 1) {
                it = ua_maps[i].erase(it);
            } else {
                it++;
            }
        }
        for (auto it = ub_maps[i].begin(); it != ub_maps[i].end(); ) {
            auto [e, n] = *it;
            if (n > 1) {
                it = ub_maps[i].erase(it);
            } else {
                it++;
            }
        }
        lp_maps[i].reserve(large.size());
        for (auto pos = 0; pos < large.size(); pos++) {
            lp_maps[i].insert({_rules[i](large[pos].e_text), pos});
        }
    }

    std::vector<_sym_pos> uc_pos;
    uc_pos.reserve(small.size());
    for (auto i = 0; i < small.size(); i++) {
        auto& e = small[i];
        if (!e.e_text.size()) continue;
        // for the element e, loop throgh all rule results
        // to see if there is a match with any of the rules
        for (auto j = 0; j < _rules.size(); j++) {
            auto simplified = _rules[j](e.e_text);
            //LOG << "rule" << j << ": " << simplified;
            auto rh = std::hash<std::string>{}(simplified);
            auto found_in_a = (ua_maps[j].find(rh) != ua_maps[j].end());
            auto found_in_b = (ub_maps[j].find(rh) != ub_maps[j].end());
            if (found_in_a && found_in_b) {
                _sym_pos sp = {e.e_hash};
                const auto index_in_large = (lp_maps[j])[simplified];
                if (A.size() <= B.size()) { // i is from A
                    sp.pos_in_a.push_back(i);
                    sp.pos_in_b.push_back(index_in_large);
                } else { // i is from B
                    sp.pos_in_a.push_back(index_in_large);
                    sp.pos_in_b.push_back(i);
                }
                uc_pos.emplace_back(sp);
                break;
            }
        }
    }
    return uc_pos;
}

template<typename T>
auto CompareManager::processDiffSections(T& A, T& B, const std::vector<int>& sp) {
    int i = 0;
    std::vector<std::pair<T, T>> sections;
    for (auto j = 0; j < sp.size(); j++) {
        auto e = sp[j];
        //LOG << "section at " << i << "," << e;
        // range [first, last)
        std::vector<CompareFileModel::Element> sub_a(A.begin() + i, A.begin() + e);
        std::vector<CompareFileModel::Element> sub_b(B.begin() + i, B.begin() + e);
        sections.push_back({sub_a, sub_b});
        sections.push_back({{A[e]},{B[e]}});
        i = sp[j] + 1;
    }

    i = sp.back() + 1;
    auto e = static_cast<int>(std::min(A.size(), B.size())) - 1;
    //LOG << "last section at " << i << "," << e;
    std::vector<CompareFileModel::Element> sub_a(A.begin() + i, A.end());
    std::vector<CompareFileModel::Element> sub_b(B.begin() + i, B.end());
    sections.push_back({sub_a, sub_b});

    //LOG << "dumping sections...";
    for (const auto& [sa, sb] : sections) {
        dumpModels(sa, sb, "section");
    }
    //LOG << "processSection...";
    for (auto& [sa, sb] : sections) {
        if (sa.size() > 1){
            processSection(sa, sb);
        }
    }

    A.clear();
    B.clear();

    for (auto& [sa, sb] : sections) {
       A.insert(A.end(), sa.begin(), sa.end());
       B.insert(B.end(), sb.begin(), sb.end());
    }
}

template<typename T>
auto CompareManager::processSection(T& sub_a, T&sub_b) {
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
    removeNotRealPairs(sub_a, sub_b);
    compareRoot(sub_a, sub_b);
    // make sections equal again after comparision
    auto delta = std::abs(
        static_cast<int>(sub_a.size() - sub_b.size()));
    if (sub_a.size() > sub_b.size()) {
        sub_b.insert(sub_b.end(), delta, {});
    } else if (sub_a.size() < sub_b.size()) {
        sub_a.insert(sub_a.end(), delta, {});
    }
    removeNotRealPairs(sub_a, sub_b);
}

template<typename T>
auto CompareManager::alignUniqueCommonSymbols(T& A, T&B, std::vector<_sym_pos>& uc_pos) {
    uint32_t added_in_a = 0;
    uint32_t added_in_b = 0;
    std::vector<int> section_points;
    for (auto it = uc_pos.begin(); it != uc_pos.end(); ) {
        auto& p = *it;
        auto in_a = p.pos_in_a[0];
        auto in_b = p.pos_in_b[0];
        in_a += added_in_a;
        in_b += added_in_b;
        auto n = std::abs(in_a - in_b);
        auto& ta = A[in_a].e_text; //debug
        auto& tb = B[in_b].e_text; //debug
        if (in_a != in_b) {
            // check if we have any matching positions
            // after this entry in the uc_pos. if yes,
            // then we skip this one as it would screw
            // up the subsequent matched entry's alingment
            auto it_matched = std::find_if(it, uc_pos.end(),
                [](const auto& p){
                    return (p.pos_in_a[0] == p.pos_in_b[0]);
                });
            if (it_matched == uc_pos.end()) {
                if (in_a < in_b) {
                    A.insert(A.begin() + in_a, n, {0, "", {0, 0}});
                    added_in_a += n;
                    assert((in_a + n) == in_b);
                    section_points.push_back(in_b);
                } else if (in_b < in_a) {
                    B.insert(B.begin() + in_b, n, {0, "", {0, 0}});
                    added_in_b += n;
                    assert(in_a == (in_b + n));
                    section_points.push_back(in_a);
                }
                it++;
            } else {
               it = uc_pos.erase(it);
               LOG << "skipping position " << in_a << ", " << in_b;
            }
        } else {
            it++;
            section_points.push_back(in_a);
        }
    }

    return section_points;
}

template<typename T>
auto CompareManager::alignLcsSymbols(T& A, T&B, std::vector<_sym_pos>& pos, int n) {
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
                assert((in_a + n) == in_b);
            } else if (in_b < in_a) {
                B.insert(B.begin() + in_b, n, {0, "", {0, 0}});
                added_in_b += n;
                assert(in_a == (in_b + n));
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
    return (added_in_a || added_in_b || n_aligned);
}

template<typename T>
void CompareManager::compareRoot(T& A, T&B) {

    dumpModels(A, B, "compare Root");
    auto uc_pos = getUniqueCommonPosVector(A, B);

    if (uc_pos.size()) {
        auto section_points = alignUniqueCommonSymbols(A, B, uc_pos);
        dumpModels(A, B, "after align");
        if (section_points.size()) {
            processDiffSections(A, B, section_points);
            dumpModels(A, B, "after processDiffSections");
        }
    } else {
        auto [ha, hb] = getHashVectorsFromModels(A, B);
        auto r = osl::find_lcs<std::vector<size_t>>(ha, hb);
        if (r.ss.size()) {
            // use the first
            auto& lcs = r.ss[0];
            // vector of all lcs symbol positions in A and B
            auto [lcs_pos, fully_aligned] = getLcsPosVector(lcs, ha, hb);
            // loop through all lcs hashes and adjust models
            // A and B to align LCS symbols. skip duplicates
            if (!fully_aligned) {
                auto n = 1;
                while (true) {
                    auto rc = alignLcsSymbols(A, B, lcs_pos, n++);
                    if (rc) break;
                }
            }
        } else {
            makeEqual(A, B);
        }
    }
    removeNotRealPairs(A, B);
    finalizeDisplayAttributes(A, B);
}

template<typename T>
auto CompareManager::compareGranular(T& A, T&B) {
    for (auto i = 0; i < std::min(A.size(), B.size()); i++) {
        if (A[i].e_hash != B[i].e_hash) {
            auto& la = A[i].e_text;
            auto& lb = B[i].e_text;
            if (la.size() && lb.size()) {
                std::vector<CompareFileModel::Element> CA;
                std::vector<CompareFileModel::Element> CB;
                for (auto& c : la) {
                    auto h = std::hash<unsigned char>{}(c);
                    CA.push_back({h, {c}, {1, 0}});
                }
                for (auto& c : lb) {
                    auto h = std::hash<unsigned char>{}(c);
                    CB.push_back({h, {c}, {1, 0}});
                }
                compareRoot(CA, CB);
                A[i].e_child = std::move(CA);
                B[i].e_child = std::move(CB);
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
    compareRoot(A, B);
    compareGranular(A, B);
    comparisionDone = true;
    _file_models[1]->endResetModel();
    _file_models[0]->endResetModel();
    return 0;
}

// std::string q = "GAC";
// std::string p = "AGCAT";
// auto results = osl::find_lcs<std::string>(p, q);
// for (const auto& result : results.ss) {
//     result;
// }