#include <Logger.h>

#include <QVariant>

Logger::Logger()
{
  osl::Log::SetLogSink<std::wstring>(
    [this](int sev, const std::wstring& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, sev, log](){
          if (sev != osl::Log::Status)
            emit this->addLogLine(sev, QString::fromStdWString(log).trimmed());
          else
            emit this->updateStatus(QString::fromStdWString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
  osl::Log::SetLogSink<std::string>(
    [this](int sev, const std::string& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, sev, log](){
          if (sev != osl::Log::Status)
            emit this->addLogLine(sev, QString::fromStdString(log).trimmed());
          else
            emit this->updateStatus(QString::fromStdString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
}

Logger::~Logger()
{
}
