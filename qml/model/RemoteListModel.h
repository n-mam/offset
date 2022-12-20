#ifndef REMOTELISTMODEL
#define REMOTELISTMODEL

#include <QAbstractListModel>

class RemoteListModel : public QAbstractListModel
{
  Q_OBJECT

  public:

  RemoteListModel();
  ~RemoteListModel();

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

  Q_INVOKABLE void InitConnect(QString host, QString port, QString user, QString password);

  protected:

};

#endif