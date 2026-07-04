#ifndef SERIAL_PORT_MANAGER_H
#define SERIAL_PORT_MANAGER_H

#include <QObject>
#include <QString>
#include <QByteArray>
#include <QSerialPort>

#include <functional>

using ReadCallback = std::function<void (const QByteArray&)>;

struct SerialPortManager : public QObject {

    Q_OBJECT

    public:
    
    SerialPortManager(const QString& portName, QObject* parent = nullptr);
    void set_read_callback(ReadCallback cbk);
    
    public slots:
    
    void start();
    void stop();

    signals:
    
    void lineReceived(const QByteArray& line);

    private slots:
    
    void onReadyRead();

    private:

    QString _portName;
    QByteArray _buffer;
    ReadCallback _readCallback;
    QSerialPort* _port = nullptr;
};

#endif