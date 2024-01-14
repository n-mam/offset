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

    public:

    CompareManager();
    ~CompareManager();

    Q_INVOKABLE void setCompareFileModel(CompareFileModel *model);

    private:

    void compare();
    auto computeMedian(const std::unordered_map<size_t, _lcs_sym_pos>&);
    void pickNearestToMedian(std::vector<int>& vec, int median);

    std::vector<CompareFileModel *> m_models;
};

#endif