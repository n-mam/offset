#ifndef FLOOR_HPP
#define FLOOR_HPP

#include <QObject>

struct FloorManager : public QObject {

    Q_OBJECT

    public:

    FloorManager();
    ~FloorManager();

    Q_INVOKABLE void saveToFile(QString path, QString json);
};

#endif