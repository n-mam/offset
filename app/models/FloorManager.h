#ifndef FLOOR_HPP
#define FLOOR_HPP

#include <QFile>
#include <QDebug>
#include <QObject>
#include <QTextStream>

struct FloorManager : public QObject {

    Q_OBJECT

    public:

    FloorManager();
    ~FloorManager();

    Q_INVOKABLE QString loadFromFile(QString path);
    Q_INVOKABLE void saveToFile(QString path, QString json);
};

#endif