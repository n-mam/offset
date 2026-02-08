#include <QFile>
#include <QDebug>
#include <QTextStream>

#include <FloorManager.h>

FloorManager::FloorManager(){}
FloorManager::~FloorManager(){}

void FloorManager::saveToFile(QString path, QString json) {
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly|QIODevice::Truncate|QIODevice::Text)) {
        qWarning() << "Failed to open file for writing:" << path
            << "-" << file.errorString();
        return;
    }
    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << json;
    file.close();
}
