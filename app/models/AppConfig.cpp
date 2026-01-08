#include <AppConfig.h>

#include <QFile>
#include <QTextStream>

QString AppConfig::readCameraConfiguration(QString cfgPath){
    QFile f(cfgPath);
    f.open(QFile::ReadOnly|QFile::Text);
    QTextStream in(&f);
    return in.readAll();
}