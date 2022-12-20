#include <npl/protocol/ftp>

#include <RemoteListModel.h>

RemoteListModel::RemoteListModel()
{

}

RemoteListModel::~RemoteListModel()
{

}

int RemoteListModel::rowCount(const QModelIndex &parent) const
{
  return 0;
}

QVariant RemoteListModel::data(const QModelIndex &index, int role) const
{
  return QVariant();
}

void RemoteListModel::InitConnect(QString host, QString port, QString user, QString password)
{
  LOG << host.toStdString() << port.toStdString() << user.toStdString() << password.toStdString();
}