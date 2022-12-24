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
  roles.insert(ESelected, "elementSelected");
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

    case ESelected:
    {
      return m_model[row].m_selected;
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

bool FTPModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  switch (role)
  {
    case ESelected:
    {
      m_model[index.row()].m_selected = value.toBool();
    }
    default:
    break;
  }
  return true;
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
          m_fileCount = m_folderCount = 0;          
          auto feList = ParseMLSDList(list);
          QMetaObject::invokeMethod(this, [this, feList](){
            beginResetModel();
            m_model.clear();
            m_model = feList;
            setConnected(true);
            emit directoryList();
            endResetModel();
          }, Qt::QueuedConnection);
        }
        return true;
      }, npl::TLS::Yes);
  }
}

QString FTPModel::getTotalFilesAndFolder(void)
{
  return QString::number(m_fileCount) + ":" + QString::number(m_folderCount);
}

// type=dir;modify=20221129050708.519;perms=cple; symbols
// type=dir;modify=20221223154036.441;perms=cple; System Volume Information
// type=dir;modify=20221222045647.133;perms=cple; test
// type=dir;modify=20221015164516.306;perms=cple; Users

auto FTPModel::ParseMLSDList(const std::string& list) -> std::vector<FileElement>
{
  std::vector<FileElement> feList;

  auto lines = osl::split(list, "\r\n");

  if (m_currentDirectory != "/")
    feList.push_back({"..", "", "", "d"});

  for (auto& line : lines)
  {
    if (!line.size()) continue;

    auto tokens = osl::split(line, ";");

    feList.push_back({
      osl::trim(tokens.back(), " "),
      "",
      "",
      tokens.front() == "type=dir" ? "d" : "-",
      false
    });
  }

  std::partition(feList.begin(), feList.end(), 
    [](const FileElement& e){ return e.m_attributes[0] != '-'; });

  return feList;
}

auto FTPModel::ParseLinuxDirectoryList(const std::string& list) -> std::vector<FileElement>
{
  //LOG << list;
  // -rw-rw-rw- 1 ftp    ftp       1468320 Oct 15 17:37 a b c
  std::vector<FileElement> feList;

  auto lines = osl::split(list, "\r\n");

  if (m_currentDirectory != "/")
    feList.push_back({"..", "", "", "d"});

  for (auto& line : lines)
  {
    if (!line.size()) continue;

    FileElement fe;

    auto p = line.c_str();

    fe.m_attributes.append(p, 10), p += 10;

    (fe.m_attributes[0] == 'd') ? m_folderCount++ : m_fileCount++;

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

    feList.push_back(fe);
  }

  std::partition(feList.begin(), feList.end(), 
    [](const FileElement& e){ return e.m_attributes[0] != '-'; });

  return feList;
}
