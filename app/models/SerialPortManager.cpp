#include <QDebug>

#include <SerialPortManager.h>

SerialPortManager::SerialPortManager(
    const QString& portName, QObject* parent)
        : QObject(parent), _portName(portName) {}

void SerialPortManager::start() {
    _port = new QSerialPort(_portName);
    _port->setBaudRate(QSerialPort::Baud115200);
    _port->setDataBits(QSerialPort::Data8);
    _port->setParity(QSerialPort::NoParity);
    _port->setStopBits(QSerialPort::OneStop);
    _port->setFlowControl(QSerialPort::NoFlowControl);
    connect(_port, &QSerialPort::readyRead,
        this, &SerialPortManager::onReadyRead);
    if (!_port->open(QIODevice::ReadOnly)) {
        qDebug() << "Failed to open serial port:" << _portName;
        return;
    }
    _port->setDataTerminalReady(true);
    _port->setRequestToSend(true);    
}

void SerialPortManager::stop() {
    if (_port) {
        _port->close();
        delete _port;
        _port = nullptr;
    }
}

void SerialPortManager::onReadyRead() {
    _buffer += _port->readAll();
    int idx;
    while ((idx = _buffer.indexOf('\n')) != -1) {
        QByteArray line = _buffer.left(idx);
        _buffer.remove(0, idx + 1);
        //emit lineReceived(line);
        if (_readCallback) {
            _readCallback(line);
        }
    }
}

void SerialPortManager::set_read_callback(ReadCallback cbk) {
    _readCallback = cbk;
}