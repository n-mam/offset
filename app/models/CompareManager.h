#ifndef COMPARE_H
#define COMPARE_H

#include <QObject>
#include <QString>

#include <functional>

#include <CompareFileModel.h>

class CompareManager : public QObject {

    Q_OBJECT
    struct _sym_pos {
        size_t e;
        std::vector<int> pos_in_a;
        std::vector<int> pos_in_b;
    };

    public:
    CompareManager();
    ~CompareManager();

    void onFileModelChanged(CompareFileModel *model);
    void setCompareFileModel(CompareFileModel *model);

    Q_INVOKABLE size_t compare();
    Q_INVOKABLE size_t getNextDiffIndex();
    Q_INVOKABLE size_t getPrevDiffIndex();

    using TRuleFunction = std::function<std::string (const std::string&)>;

    private:

    template<typename T>
    auto makeEqual(T& A, T& B);

    template<typename T>
    void compareRoot(T& A, T&B);

    template<typename T>
    auto resetToInitialState(T& A);

    template<typename T>
    auto compareGranular(T& A, T&B);

    template<typename T>
    auto processDiffSections(T& A, T& B, const std::vector<int>& sp);

    template<typename T>
    auto finalizeDisplayAttributes(T& A, T& B);

    template<typename T>
    auto processSection(T& sub_a, T& sub_b);

    template <typename T>
    auto getHashVectorsFromModels(const T& A, const T& B);

    template <typename T>
    auto getSimplifiedHashVectors(const T& A, const T& B,TRuleFunction fn);

    template<typename T>
    auto getLcsPosVector(const T& lcs, const T& ha, const T& hb);

    template<typename T>
    auto alignLcsSymbols(T& A, T&B, std::vector<_sym_pos>& lcs_pos, int n);

    template<typename T>
    auto alignUniqueCommonSymbols(T& A, T&B, std::vector<_sym_pos>& uc_pos);

    template<typename T>
    auto dumpModels(const T& A, const T&B, const std::string&);

    template<typename T>
    auto getUniqueCommonPosVector(const T& A, const T& B);

    template<typename T>
    auto removeNotRealPairs(T& A, T&B);

    bool comparisionDone = false;
    int64_t currentDiffIndex = -1;
    std::vector<CompareFileModel *> _file_models;

    std::vector<TRuleFunction> _rules = {
            [](const std::string& a){
                auto s = a;
                s.erase(std::unique(s.begin(), s.end()), s.end());
                std::ranges::for_each(s, [](auto& c) { c = std::tolower(c); });
                return s;
            },
            [](const std::string& a){
                auto s = a;
                s.erase(std::remove_if(s.begin(), s.end(),
                    [](const auto& e){ return !std::isalnum(e); }), s.end());
                return s;
            }
        };
};

#endif