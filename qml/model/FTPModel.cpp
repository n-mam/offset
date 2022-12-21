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
        if (b) {
          list.append(b, n);
        } else {
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
  //LOG << list;
  // -rw-rw-rw- 1 ftp    ftp       1468320 Oct 15 17:37 a b c
  auto lines = osl::split(list, "\r\n");

  beginResetModel();

  m_model.clear();

  for (auto& line : lines)
  {
    if (!line.size()) continue;

    FileElement fe;

    auto p = line.c_str();

    fe.m_attributes.append(p, 10), p += 10;

    for (int i = 0; i < 3; i++) {
      while(*p == ' ') { p++; }
      while(*p != ' ') { p++; }      
    }
    
    while(*p == ' ') { p++; }
    while(*p != ' ') {
      fe.m_size.append(1, *p);
      p++;
    }

    while(*p == ' ') { p++; }

    int count = 0;
    while(count != 3)
    {
      fe.m_timestamp.append(1, *p);
      p++;
      if (*p == ' ') {
        count++;
        fe.m_timestamp.append(1, *p);
        while(*p == ' ') { p++; }
      }
    }

    while(*p == ' ') { p++; }

    fe.m_name.append(p);

    m_model.push_back(fe);
  }

  std::partition(m_model.begin(), m_model.end(), 
    [](const FileElement& e){ return e.m_attributes[0] != '-'; });

  endResetModel();

  return false;
}
