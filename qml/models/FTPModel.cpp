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

bool FTPModel::Connect(QString host, QString port, QString user, QString password, QString protocol)
{
  m_ftp = npl::make_ftp(host.toStdString(), port.toInt(), npl::TLS::Yes);

  if (!m_ftp) return false;

  m_ftp->SetCredentials(user.toStdString(), password.toStdString());

  m_ftp->StartClient();

  this->setCurrentDirectory("/");

  return true;
}

void FTPModel::Upload(QString path)
{

}

void FTPModel::Download(QString path)
{
  m_ftp->Transfer(npl::ProtocolFTP::EDirection::Download, path.toStdString(),
    [](const char *b, size_t n){
      if (b)
      {

      }
      return true;
    }, npl::TLS::Yes);
}

void FTPModel::RemoveFile(QString path, bool local)
{
  if (local) 
  {
    try
    {
      std::filesystem::remove(path.toStdString());
    }
    catch(const std::filesystem::filesystem_error& err)
    {
      LOG << "RemoveFile error: " << err.what();
    }
  }
  else
  {
    m_ftp->RemoveFile(path.toStdString());
    setCurrentDirectory(QString::fromStdString(m_currentDirectory));
  }
}

void FTPModel::RemoveDirectory(QString path, bool local)
{
  if (local)
  {
    try
    {
      std::filesystem::remove_all(path.toStdString());
    }
    catch(const std::filesystem::filesystem_error& err)
    {
      LOG << "RemoveDirectory error: " << err.what();
    }
  }
  else
  {
    m_ftp->RemoveDirectory(path.toStdString());
    setCurrentDirectory(QString::fromStdString(m_currentDirectory));
  }
}

void FTPModel::CreateDirectory(QString path, bool local)
{
  if (local)
  {
    try
    {
      std::filesystem::create_directory(path.toStdString());
    }
    catch(const std::exception& e)
    {
      LOG << e.what();
    }
  }
  else
  {
    m_ftp->CreateDirectory(path.toStdString());
    setCurrentDirectory(QString::fromStdString(m_currentDirectory));
  }
}

void FTPModel::Rename(QString from, QString to, bool local)
{
  if (local)
  {
    try
    {
      std::filesystem::rename(from.toStdString(), to.toStdString());
    }
    catch(const std::exception& e)
    {
      LOG << e.what();
    }
  }
  else
  {
    m_ftp->Rename(from.toStdString(), to.toStdString());
    setCurrentDirectory(QString::fromStdString(m_currentDirectory));
  }
}

void FTPModel::Quit()
{
  m_ftp->Quit();
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
  m_currentDirectory = directory.toStdString();

  m_ftp->SetCurrentDirectory(m_currentDirectory);

  m_ftp->Transfer(npl::ProtocolFTP::EDirection::List, m_currentDirectory,
    [this, list = std::string()] (const char *b, size_t n) mutable {
      if (b) {
        list.append(b, n);
      } else {
        //LOG << list;
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

QString FTPModel::getTotalFilesAndFolder(void)
{
  return QString::number(m_fileCount) + ":" + QString::number(m_folderCount);
}

// type=dir;modify=20221223154036.441;perms=cple; System Volume Information
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
      osl::trim(tokens.back(), " "), "", "",
      tokens.front() == "type=dir" ? "d" : "-",
      false
    });
  }

  std::partition(feList.begin(), feList.end(), 
    [](const FileElement& e){ return e.m_attributes[0] != '-'; });

  return feList;
}

// -rw-rw-rw- 1 ftp    ftp       1468320 Oct 15 17:37 a b c
auto FTPModel::ParseLinuxDirectoryList(const std::string& list) -> std::vector<FileElement>
{
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
