#ifndef COMPARE_H
#define COMPARE_H

#include <QObject>
#include <QString>

#include <CompareFileModel.h>

class CompareManager : public QObject {

    Q_OBJECT

    struct _lcs_sym_pos {
        std::vector<int> pos_in_a;
        std::vector<int> pos_in_b;
    };
    struct _lcs_sym_pos_matched {
        int pos_in_a;
        int pos_in_b;
    };
    public:

    CompareManager();
    ~CompareManager();

    void setCompareFileModel(CompareFileModel *model);

    Q_INVOKABLE void compare();

    public slots:

    void onFileModelChanged(CompareFileModel *model);

    private:

    void pickNearestToMedian(std::vector<int>& vec, int median);
    auto computeMedian(const std::unordered_map<size_t, _lcs_sym_pos>&);

    std::vector<CompareFileModel *> _models;
};

#endif