#ifndef COMPARE_H
#define COMPARE_H

#include <QObject>
#include <QString>

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

    Q_INVOKABLE size_t compare();
    Q_INVOKABLE size_t getNextDiffIndex();
    Q_INVOKABLE size_t getPrevDiffIndex();

    void onFileModelChanged(CompareFileModel *model);
    void setCompareFileModel(CompareFileModel *model);

    public slots:

    private:

    template<typename T>
    auto makeEqual(T& A, T& B);

    template<typename T>
    size_t compareRoot(T& A, T&B);

    template<typename T>
    auto resetToInitialState(T& A);

    template<typename T>
    auto compareGranular(T& A, T&B);

    template<typename T>
    auto processDiffSections(T& A, T& B);

    template<typename T>
    auto finalizeDisplayAttributes(T& A, T& B);

    template<typename T>
    auto processSection(T& A, T&B, int i, int j);

    template <typename T>
    auto getHashVectorsFromModels(const T& A, const T& B);

    template<typename T>
    auto getLcsPosVector(const T& lcs, const T& ha, const T& hb);

    template<typename T>
    auto align(T& A, T&B, std::vector<_sym_pos>& lcs_pos, int n);

    template<typename T>
    auto dumpModels(const T& A, const T&B, const std::string&);

    template<typename T>
    auto getUniqueCommonPosVector(T& A, T&B);

    template<typename T>
    auto removeNotRealPairs(T& A, T&B);

    bool comparisionDone = false;
    int64_t currentDiffIndex = -1;
    std::vector<CompareFileModel *> _file_models;
};

#endif