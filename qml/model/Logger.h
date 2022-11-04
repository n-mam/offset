#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <QObject>

class Logger : public QObject
{
  Q_OBJECT

  public:

  Logger();
  ~Logger();

  signals:

  void addLogLine(QVariant);
};

#endif