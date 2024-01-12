#ifndef COMPARE_H
#define COMPARE_H

#include <QObject>
#include <QString>

#include <CompareFileModel.h>

class CompareManager : public QObject {

    Q_OBJECT

    public:

    CompareManager();
    ~CompareManager();

    Q_INVOKABLE void setCompareFileModel(CompareFileModel *model);

};

#endif