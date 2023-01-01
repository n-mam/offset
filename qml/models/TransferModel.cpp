#include <FTPModel.h>
#include <TransferModel.h>

TransferModel::TransferModel(FTPModel *ftpModel)
{
  m_ftpModel = ftpModel;
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
  roles.insert(EProgress, "progress");

  return roles;
}

int TransferModel::rowCount(const QModelIndex& parent) const
{
  return m_queue.size();
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
      return QString::fromStdString(m_queue[row].m_local);
    }
    case ERemote:
    {
      return QString::fromStdString(m_queue[row].m_remote);
    }
    case EDirection:
    {
      return (int)(m_queue[row].m_direction);
    }
    case EType:
    {
      return m_queue[row].m_type;
    }
    case EProgress:
    {
      return m_queue[row].m_progress;
    }
    default:
      break;
  }

  return QVariant();
}

void TransferModel::AddToTransferQueue(Transfer&& transfer)
{
  QMetaObject::invokeMethod(this, [=]() mutable {
    transfer.m_index = m_queue.size();
    beginInsertRows(QModelIndex(), 
      transfer.m_index, transfer.m_index);
    m_queue.push_back(transfer);
    endInsertRows();
    ProcessTransfer(m_queue.back());
  });
}

void TransferModel::ProcessTransfer(Transfer& t)
{
  while (m_sessions.size() != MAX_SESSIONS)
    CreateFTPSession();

  auto& ftp = m_sessions[m_next_session];

  if (t.m_direction == npl::ProtocolFTP::EDirection::Download)
  {
    auto file = std::make_shared<npl::FileDevice>(t.m_local, true);

    ftp->Transfer(t.m_direction, t.m_remote,
      [=, &t, offset = 0ULL](const char *b, size_t n) mutable {
        if (b)
        {
          file->Write((uint8_t *)b, n, offset);
          offset += n;
        }
        else
        {
          LOG << "Download complete";
          file.reset();
        }
        t.m_progress = b ? (((float)offset / t.m_size) * 100) : 100;
        QMetaObject::invokeMethod(this, [=]() mutable {
          emit dataChanged(index(t.m_index), index(t.m_index), {Roles::EProgress});
        });
        return true;
      }, m_ftpModel->m_protection);
  }
  else if (t.m_direction == npl::ProtocolFTP::EDirection::Upload)
  {
    assert(false);
  }

  m_next_session = (m_next_session + 1) % MAX_SESSIONS;
}

void TransferModel::CreateFTPSession(void)
{
  auto ftp = npl::make_ftp(
    m_ftpModel->m_host, m_ftpModel->m_port, m_ftpModel->m_protection);

  if (!ftp) return;

  ftp->SetCredentials(m_ftpModel->m_user, m_ftpModel->m_password);

  ftp->StartClient(
    [this](auto p, bool isConnected){
      if(!isConnected) {

      }
    }
  );

  m_sessions.push_back(ftp);
}