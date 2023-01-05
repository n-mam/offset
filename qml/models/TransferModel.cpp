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

void TransferModel::AddToTransferQueue(const Transfer& transfer)
{
  QMetaObject::invokeMethod(this,
    [=, t = std::move(transfer)]() mutable {
      t.m_index = m_queue.size();
      beginInsertRows(QModelIndex(), t.m_index, t.m_index);
      m_queue.emplace_back(t);
      endInsertRows();
    });
}

void TransferModel::ProcessAllTransfers(void)
{
  for (int i = 0; i < m_queue.size(); i++)
  {
    auto& t = m_queue[i];

    if (!t.m_done)
    {
      //ProcessTransfer(i);
    }
  }
}

void TransferModel::ProcessTransfer(int row)
{
  while (m_sessions.size() != MAX_SESSIONS)
    CreateFTPSession();

  Transfer& t = (row < 0) ? m_queue.back() : m_queue[row];

  if (t.m_direction == npl::ProtocolFTP::EDirection::Download)
  {
    std::filesystem::path path = t.m_local;
    std::filesystem::create_directories(path.parent_path());

    auto file = std::make_shared<npl::FileDevice>(t.m_local, true);

    auto& ftp = m_sessions[m_next_session];

    ftp->Transfer(t.m_direction, t.m_remote,
      [=, idx = t.m_index, offset = 0ULL](const char *b, size_t n) mutable {
        if (b)
        {
          file->Write((uint8_t *)b, n, offset);
          offset += n;
        }
        else
        {
          file.reset();
        }

        auto& tt = m_queue[idx];

        if (tt.m_size) {
          tt.m_progress = b ?
            (((float)offset / tt.m_size) * 100) : 100;
        }

        QMetaObject::invokeMethod(this, [=](){
          emit dataChanged(index(idx), index(idx), {Roles::EProgress});
        });

        return true;
      },
      m_ftpModel->m_protection);
  }
  else if (t.m_direction == npl::ProtocolFTP::EDirection::Upload)
  {
    
  }

  m_next_session = (m_next_session + 1) % MAX_SESSIONS;
}

void TransferModel::DeleteTransfer(int row)
{
  beginResetModel();
  if (row < 0)
    m_queue.clear();
  else
    m_queue.erase(m_queue.begin() + row);
  endResetModel();
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