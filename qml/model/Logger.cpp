#include <Logger.h>

#include <QVariant>

Logger::Logger()
{
  osl::Log::SetLogSink<std::wstring>(
    [this](const std::wstring& log){
      if (log.size()) {
        QMetaObject::invokeMethod(this, [this, log](){
          emit this->addLogLine(QString::fromStdWString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
  osl::Log::SetLogSink<std::string>(
    [this](const std::string& log){
      if (log.size()) {
        QMetaObject::invokeMethod(this, [this, log](){
          emit this->addLogLine(QString::fromStdString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
}

Logger::~Logger()
{
}

