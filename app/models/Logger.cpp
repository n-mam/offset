#include <npl/npl>
#include <osl/log>

#include <Logger.h>

Logger::Logger() {
  osl::log::setLogLevel(osl::log::debug);
  osl::log::setLogSink<std::wstring>(
    [this](int level, int key, const std::wstring& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, level, key, log](){
          if (level != osl::log::status)
            emit this->addLogLine(level, QString::fromStdWString(log).trimmed());
          else
            emit this->updateStatus(key, QString::fromStdWString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
  osl::log::setLogSink<std::string>(
    [this](int level, int key, const std::string& log){
      if (!log.empty()) {
        QMetaObject::invokeMethod(this, [this, level, key, log](){
          if (level != osl::log::status)
            emit this->addLogLine(level, QString::fromStdString(log).trimmed());
          else
            emit this->updateStatus(key, QString::fromStdString(log).trimmed());
        }, Qt::QueuedConnection);
      }
    });
  npl::make_dispatcher();
}

Logger::~Logger(){}
