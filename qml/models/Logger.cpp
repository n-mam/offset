#include <Logger.h>

#include <QVariant>

Logger::Logger()
{
  osl::log::SetLogSink<std::wstring>(
    [this](int sev, int key, const std::wstring& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, sev, key, log](){
          if (sev != osl::log::status)
            emit this->addLogLine(sev, QString::fromStdWString(log).trimmed());
          else
            emit this->updateStatus(key, QString::fromStdWString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
  osl::log::SetLogSink<std::string>(
    [this](int sev, int key, const std::string& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, sev, key, log](){
          if (sev != osl::log::status)
            emit this->addLogLine(sev, QString::fromStdString(log).trimmed());
          else
            emit this->updateStatus(key, QString::fromStdString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
}

Logger::~Logger()
{
}
