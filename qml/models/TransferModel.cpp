#include <TransferModel.h>

TransferModel::TransferModel()
{
}

TransferModel::~TransferModel()
{
}

QHash<int, QByteArray> TransferModel::roleNames() const
{
  auto roles = QAbstractListModel::roleNames();

  roles.insert(ELocal, "local");
  roles.insert(ERemote, "remote");
  roles.insert(EDirection, "direction");
  roles.insert(EType, "type");

  return roles;
}

int TransferModel::rowCount(const QModelIndex& parent) const
{
  return m_transfers.size();
}

QVariant TransferModel::data(const QModelIndex& index, int role) const
{
  if (!index.isValid())
    return QVariant();

  auto row = index.row();

  switch (role)
  {
    case ELocal:
    {
      return QString::fromStdString(m_transfers[row].m_local);
    }
    case ERemote:
    {
      return QString::fromStdString(m_transfers[row].m_remote);
    }
    case EDirection:
    {
      return (int)(m_transfers[row].m_direction);
    }
    case EType:
    {
      return m_transfers[row].m_type;
    }
    default:
      break;
  }

  return QVariant();
}

void TransferModel::AddToTransferQueue(const Transfer& transfer)
{
  QMetaObject::invokeMethod(this, [=](){
    int row = m_transfers.size();
    beginInsertRows(QModelIndex(), row, row);
    m_transfers.push_back(transfer);
    endInsertRows();
  });
}