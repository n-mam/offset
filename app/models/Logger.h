#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>

class Logger : public QObject {
  Q_OBJECT
  public:
  Logger();
  ~Logger();
  signals:
  void addLogLine(int, QString);
  void updateStatus(int, QString);
};

#endif