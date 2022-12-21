#include <FTPModel.h>

FTPModel::FTPModel()
{
}

FTPModel::~FTPModel()
{
}

QHash<int, QByteArray> FTPModel::roleNames() const
{
  auto roles = QAbstractListModel::roleNames();

  roles.insert(EFileName, "fileName");
  roles.insert(EFileSize, "fileSize");
  roles.insert(EFileIsDir, "fileIsDir");
  roles.insert(EFileAttributes, "fileAttributes");

  return roles;
}

int FTPModel::rowCount(const QModelIndex &parent) const
{
  return m_model.size();
}

QVariant FTPModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  auto row = index.row();

  switch (role)
  {
    case EFileName:
    {
      return QString::fromStdString(m_model[row].m_name);
    }

    case EFileIsDir:
    {
      return ((m_model[row].m_attributes)[0] == 'd');
    }

    case EFileSize:
    {
      return QString::fromStdString(m_model[row].m_size);
    }

    case EFileAttributes:
    {
      return QString::fromStdString(m_model[row].m_attributes);
    }

    default:
      return {};
  }

  return QVariant();
}

bool FTPModel::InitConnect(QString host, QString port, QString user, QString password, QString protocol)
{
  m_ftp = npl::make_ftp(host.toStdString(), port.toInt(), npl::TLS::Yes);

  if (!m_ftp) return false;

  m_ftp->SetCredentials(user.toStdString(), password.toStdString());

  m_ftp->StartClient();

  this->setCurrentDirectory("/");

  return true;
}

bool FTPModel::getConnected(void)
{
  return m_connected;
}

void FTPModel::setConnected(bool isConnected)
{
  if (m_connected != isConnected)
  {
    m_connected = isConnected;
    emit connected(m_connected);
  }
}

QString FTPModel::getCurrentDirectory(void)
{
  return QString::fromStdString(m_currentDirectory);
}

void FTPModel::setCurrentDirectory(QString directory)
{
  if (QString::fromStdString(m_currentDirectory) != directory)
  {
    m_currentDirectory = directory.toStdString();

    m_ftp->SetCurrentDirectory(m_currentDirectory);

    m_ftp->Transfer(npl::ProtocolFTP::EDirection::List, m_currentDirectory,
      [this, list = std::string()] (const char *b, size_t n) mutable {
        if (b)
        {
          list.append(std::string(b, n));
        }
        else
        {
          ParseLinuxDirectoryList(list);
          setConnected(true);
          emit directoryList();
        }
        return true;
      }, npl::TLS::Yes);
  }
}

bool FTPModel::ParseLinuxDirectoryList(const std::string& list)
{
  LOG << list;
  // -rw-rw-rw- 1 ftp ftp   1468320 Oct 15 17:37 accesschk.exe
  auto lines = osl::split(list, "\r\n");

  beginResetModel();

  m_model.clear();

  for (const auto& line : lines)
  {
    if (line.size())
    {
      auto elements = osl::split(line, " ");

      if (elements.size() > 1)
      {
        auto name = elements.back();
        auto size = elements[4];
        auto attributes = elements.front();

        if (attributes[0] == 'd')
          m_folderCount++;
        else if (attributes[0] == '-')
          m_fileCount++;

        m_model.push_back({name, size, attributes});
      }
    }
  }

  endResetModel();

  return false;
}
