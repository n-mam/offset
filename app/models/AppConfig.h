#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QObject>

class AppConfig :public QObject
{
    Q_OBJECT

    public:

    AppConfig();
    ~AppConfig();

    Q_INVOKABLE QString readCameraConfiguration(QString cfgPath);

};

#endif