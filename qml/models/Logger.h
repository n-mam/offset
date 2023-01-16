#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <osl/log>

#include <QObject>

class Logger : public QObject
{
  Q_OBJECT

  public:

  Logger();
  ~Logger();

  signals:

  void addLogLine(int, QString);
  void updateStatus(int, QString);
};

#endif