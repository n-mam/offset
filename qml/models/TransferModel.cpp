#include <FTPModel.h>
#include <TransferModel.h>

TransferModel::TransferModel(FTPModel *ftpModel)
{
  m_ftpModel = ftpModel;
  m_queue.reserve(4096);
  connect(this, &TransferModel::transferFailed, this, &TransferModel::TransferFinished);
  connect(this, &TransferModel::transferSuccessful, this, &TransferModel::TransferFinished);
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
  return static_cast<int>(m_queue.size());
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
      auto pos = m_queue.size();
      beginInsertRows(QModelIndex(), pos, pos);
      m_queue.emplace_back(t);
      endInsertRows();
      emit transferQueueSize(m_queue.size());
    });
}

int TransferModel::GetSessionWithLeastQueueDepth(void)
{
  int sid, minimum = INT_MAX;

  for (int i = 0; i < MAX_SESSIONS; i++) {
    auto pending = m_sessions[i]->PendingTransfers();
    if (pending < minimum) {
      sid = i;
      minimum = pending;      
    }
  }

  return sid;
}

void TransferModel::TransferFinished(int i)
{
  --m_activeTransfers;

  for (int j = i; j < m_queue.size(); j++) {
    if (m_queue[j].m_status == Transfer::status::queued) {
      ProcessTransfer(j, m_queue[i].m_sid);
      break;
    }
  }
}

void TransferModel::ProcessAllTransfers(void)
{
  auto limit = std::min(MAX_SESSIONS, m_queue.size());
  for (int i = 0; i < limit; i++) {
    ProcessTransfer(i, m_next_session);
    m_next_session = (m_next_session + 1) % MAX_SESSIONS;
  }
}

void TransferModel::ProcessTransfer(int row, int sid)
{
  Transfer& t = m_queue[row];

  if (t.m_status == Transfer::status::queued)
  {
    static bool b = InitializeFTPSessions();

    b ? b = false : (CheckAndReconnectSessions(), false);

    t.m_sid = (sid >= 0) ? sid : GetSessionWithLeastQueueDepth();

    t.m_index = row;

    m_activeTransfers++;

    t.m_status = Transfer::status::processing;

    emit transferStarted(t.m_index);

    if (t.m_direction == npl::ProtocolFTP::EDirection::Download)
    {
      DownloadTransfer(t, t.m_sid);
    }
    else if (t.m_direction == npl::ProtocolFTP::EDirection::Upload)
    {
      UploadTransfer(t, t.m_sid);
    }
  }
}

void TransferModel::DownloadTransfer(const Transfer& t, int sid)
{
  std::filesystem::path path = t.m_local;

  std::filesystem::create_directories(path.parent_path());

  auto file = std::make_shared<npl::FileDevice>(t.m_local, true);

  auto& ftp = m_sessions[sid];

  ftp->Transfer(t.m_direction, t.m_remote,
    [=, i = t.m_index, offset = 0ULL]
    (const char *b, size_t n) mutable {
      if (b)
      {
        file->Write((uint8_t *)b, n, offset);
        offset += n;
      }
      else
      {
        if (m_queue[i].m_status != Transfer::status::successful)
        {
          file.reset();
          QMetaObject::invokeMethod(this, [=](){
            m_queue[i].m_status = Transfer::status::successful;
            emit transferSuccessful(i, ++m_successful_transfers);
          });
        }
      }

      auto& tt = m_queue[i];

      if (tt.m_size) {
        int p = b ? (((float)offset / tt.m_size) * 100) : 100;
        if (p > tt.m_progress) {
          tt.m_progress = p;
          QMetaObject::invokeMethod(this, [=](){
            emit dataChanged(index(i), index(i), {Roles::EProgress});
          });
        }
      }

      return true;
    },
    [=, i = t.m_index](const auto& res) {
      if (res[0] == '4' || res[0] == '5') {
        QMetaObject::invokeMethod(this, [=](){
          m_queue[i].m_status = Transfer::status::failed;
          emit transferFailed(i, ++m_failed_transfers);
        });
      }
    },
    m_ftpModel->m_protection);
}

void TransferModel::UploadTransfer(const Transfer& t, int sid)
{
  std::filesystem::path path = t.m_remote;

  auto& ftp = m_sessions[sid];

  std::string directory;
  auto tokens = osl::split(path.parent_path().string(), "/");

  for (const auto& e : tokens) {
    if (!e.empty()) {
      directory += "/" + e;
      ftp->CreateDirectory(directory);
    }
  }

  auto file = std::make_shared<npl::FileDevice>(t.m_local, false);

  uint8_t *buf = (uint8_t *) calloc(1, _1M);

  ftp->Transfer(t.m_direction, t.m_remote,
    [=, i = t.m_index, offset = 0ULL]
    (const char *b, size_t l) mutable {

      auto n = file->ReadSync(buf, _1M, offset);

      if (n)
      {
        ftp->Write(buf, n);
        offset += n;
      }
      else
      {
        if (m_queue[i].m_status != Transfer::status::successful)
        {
          QMetaObject::invokeMethod(this, [=](){
            m_queue[i].m_status = Transfer::status::successful;
            emit transferSuccessful(i, ++m_successful_transfers);
          });
        }
      }

      auto& tt = m_queue[i];

      if (tt.m_size) {
        int p = b ? (((float)offset / tt.m_size) * 100) : 100;
        if (p > tt.m_progress) {
          tt.m_progress = p;
          QMetaObject::invokeMethod(this, [=](){
            emit dataChanged(index(i), index(i), {Roles::EProgress});
          });
        }
      }

      return (n > 0);
    },
    [=, i = t.m_index](const auto& res) {
      if (res[0] == '4' || res[0] == '5') {
        QMetaObject::invokeMethod(this, [=](){
          m_queue[i].m_status = Transfer::status::failed;
          emit transferFailed(i, ++m_failed_transfers);
        });
      }
    },
    m_ftpModel->m_protection);
}

void TransferModel::RemoveAllTransfers(void)
{
  if (!m_activeTransfers)
  {
    beginResetModel();
    m_queue.clear();
    emit transferQueueSize(0);
    endResetModel();
  }
}

void TransferModel::RemoveTransfer(int row)
{
  if (!m_activeTransfers)
  {
    beginRemoveRows(QModelIndex(), row, row);
    m_queue.erase(m_queue.begin() + row);
    emit transferQueueSize(static_cast<int>(m_queue.size()));
    endRemoveRows();
  }
}

bool TransferModel::InitializeFTPSessions(void)
{
  while(m_sessions.size() != MAX_SESSIONS)
  {
    auto ftp = npl::make_ftp(
      m_ftpModel->m_host, m_ftpModel->m_port, m_ftpModel->m_protection);

    if (!ftp) return false;

    ftp->SetCredentials(m_ftpModel->m_user, m_ftpModel->m_password);

    ftp->StartClient(
      [this](auto p, bool isConnected){
        if(!isConnected) { }
      });

    m_sessions.push_back(ftp);
  }

  return true;
}

void TransferModel::CheckAndReconnectSessions(void)
{
  for (size_t i = 0; i < MAX_SESSIONS; i++)
  {
    if (!m_sessions[i]->IsConnected())
    {
      m_sessions[i] = npl::make_ftp(
        m_ftpModel->m_host, m_ftpModel->m_port, m_ftpModel->m_protection);

      m_sessions[i]->SetCredentials(m_ftpModel->m_user, m_ftpModel->m_password);

      m_sessions[i]->StartClient(
        [this](auto p, bool isConnected){
          if(!isConnected) { }
        });
    }
  }
}