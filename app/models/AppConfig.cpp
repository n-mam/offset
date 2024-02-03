#include <AppConfig.h>

#include <QFile>
#include <QTextStream>

AppConfig::AppConfig(){}

AppConfig::~AppConfig(){}

QString AppConfig::readCameraConfiguration(QString cfgPath){
    QFile f(cfgPath);
    f.open(QFile::ReadOnly|QFile::Text);
    QTextStream in(&f);
    return in.readAll();
}