#ifndef COMPARE_H
#define COMPARE_H

#include <QObject>
#include <QString>

#include <CompareFileModel.h>

class CompareManager : public QObject {

    Q_OBJECT

    struct _lcs_sym_pos {
        size_t e;
        std::vector<int> pos_in_a;
        std::vector<int> pos_in_b;
    };

    public:

    CompareManager();
    ~CompareManager();

    Q_INVOKABLE size_t compare();

    void setCompareFileModel(CompareFileModel *model);

    public slots:

    void onFileModelChanged(CompareFileModel *model);

    private:

    template<typename T>
    auto compareInternal(T& A, T&B);

    template<typename T>
    auto finalizeDisplayAttributes(T& A, T& B);

    template <typename T>
    auto getHashVectorsFromModels(const T& A, const T& B);

    template<typename T>
    auto get_lcs_pos_vector(const T& lcs, const T& ha, const T& hb);

    std::vector<CompareFileModel *> _file_models;
};

#endif