#ifndef FLOOR_HPP
#define FLOOR_HPP

#include <QUrl>
#include <QFile>
#include <QDebug>
#include <QObject>
#include <QTextStream>

struct FloorManager : public QObject {

    Q_OBJECT

    public:

    FloorManager();
    ~FloorManager();

    Q_INVOKABLE QString loadFromFile(QUrl path);
    Q_INVOKABLE void saveToFile(QUrl path, QString json);
};

#endif