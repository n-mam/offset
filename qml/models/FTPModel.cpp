#include <FTPModel.h>

#include <filesystem>

FTPModel::FTPModel()
{
}

FTPModel::~FTPModel()
{
  if (m_queue)
    delete m_queue;
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
  return static_cast<int>(m_model.size());
}

QVariant FTPModel::get(int row, QString role)
{
  if (role == "fileName") {
   return data(index(row, 0), EFileName);
  } else if (role == "fileSize") {
   return data(index(row, 0), EFileSize);
  } else if (role == "fileIsDir") {
   return data(index(row, 0), EFileIsDir);
  }
  return QVariant();
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

TransferModel * FTPModel::getTransferModel(void)
{
  if (!m_queue)
  {
    m_queue = new TransferModel(this);
  }

  return m_queue;
}

bool FTPModel::Connect(QString host, QString port, QString user, QString password, QString protocol)
{
  m_port = port.toInt();
  m_host = host.toStdString();
  m_user = user.toStdString();
  m_password = password.toStdString();

  m_protection = (protocol == "FTPS") ? npl::tls::yes : npl::tls::no;

  m_ftp = npl::make_ftp(m_host, m_port , m_protection);

  if (!m_ftp) return false;

  m_ftp->SetCredentials(m_user, m_password,
    [this](bool success){
      QMetaObject::invokeMethod(this, [=](){
        if (success) {
          setRemoteDirectory("/");
        }
      }, Qt::QueuedConnection);
    });

  m_ftp->StartClient(
    [this](auto p, bool isConnected){
      QMetaObject::invokeMethod(this, [=](){
        setConnected(isConnected);
        if(!isConnected)
        {
          beginResetModel();
          m_model.clear();
          endResetModel();
        }
      }, Qt::QueuedConnection);
    });

  return true;
}

void FTPModel::Transfer(QString file, QString folder, QString localFolder, bool isFolder, bool direction, uint64_t size)
{
  if (direction)
  {
    UploadInternal(file.toStdString(), folder.toStdString(), localFolder.toStdString(), isFolder, size);
  }
  else
  {
    DownloadInternal(file.toStdString(), folder.toStdString(), localFolder.toStdString(), isFolder, size);
  }
}

void FTPModel::UploadInternal(std::string file, std::string localFolder, std::string remoteFolder, bool isFolder, uint64_t size)
{
  auto localPath = localFolder + ((localFolder.back() == path_sep) ? file : (path_sep + file));
  auto remotePath = remoteFolder + ((remoteFolder.back() == '/') ? file : ("/" + file));

  //LOG << file << " " << localFolder << " " << remoteFolder << " " << localPath << " " << remotePath;

  if (isFolder)
  {
    for (auto const& entry : std::filesystem::directory_iterator(localPath))
    {
      if (entry.is_directory()) {
        UploadInternal(
          entry.path().filename().string(),
          localPath,
          remotePath,
          true);
      }
      else if(entry.is_regular_file()) {
        m_queue->AddToTransferQueue({
          entry.path().string(),
          remotePath + "/" + entry.path().filename().string(),
          npl::ProtocolFTP::EDirection::Upload,
          'I', entry.file_size()
        });
      }
    }
  }
  else
  {
    m_queue->AddToTransferQueue({
      localPath,
      remotePath,
      npl::ProtocolFTP::EDirection::Upload,
      'I', size
    });
  }
}

void FTPModel::DownloadInternal(std::string file, std::string folder, std::string localFolder, bool isFolder, uint64_t size)
{
  auto remotePath = folder + ((folder.back() == '/') ? file : ("/" + file));
  auto localPath = localFolder + ((localFolder.back() == path_sep) ? file : (path_sep + file));

  //LOG << file << " " << folder << " " << localFolder << " " << localPath << " " << remotePath;

  if (isFolder)
  {
    WalkRemoteDirectory(remotePath, [=](const FileElement& fe){
      if (fe.m_attributes[0] == 'd') {
        DownloadInternal(
          fe.m_name,
          remotePath,
          localPath,
          true);
      }
      else {
        m_queue->AddToTransferQueue({
          localPath + path_sep + fe.m_name,
          remotePath + "/" + fe.m_name,
          npl::ProtocolFTP::EDirection::Download,
          'I', std::stoull(fe.m_size)
        });
      }});
  }
  else
  {
    m_queue->AddToTransferQueue({
      localPath,
      remotePath,
      npl::ProtocolFTP::EDirection::Download,
      'I', size
    });
  }
}

void FTPModel::WalkRemoteDirectory(const std::string& path, TFileElementCallback callback)
{
  m_ftp->Transfer(npl::ProtocolFTP::EDirection::List, path,
    [=, list = std::string()] (const char *b, size_t n) mutable {
      if (b)
      {
        list.append(b, n);
      }
      else
      {
        std::vector<FileElement> feList;
        ParseDirectoryList(list, feList);
        for (const auto& fe : feList)
          callback(fe);
      }
      return true;
    }, nullptr, m_protection);
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
      LOG << "std::filesystem::remove exception : " << err.what();
    }
  }
  else
  {
    m_ftp->RemoveFile(path.toStdString());
    RefreshRemoteView();
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
      LOG << "std::filesystem::remove_all exception : " << err.what();
    }
  }
  else
  {
    m_ftp->RemoveDirectory(path.toStdString());
    RefreshRemoteView();
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
    RefreshRemoteView();
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
    RefreshRemoteView();
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

QString FTPModel::getRemoteDirectory(void)
{
  return QString::fromStdString(m_remoteDirectory);
}

void FTPModel::setRemoteDirectory(QString directory)
{
  m_ftp->SetCurrentDirectory(directory.toStdString());

  m_ftp->Transfer(npl::ProtocolFTP::EDirection::List, directory.toStdString(),
    [=, list = std::string()] (const char *b, size_t n) mutable {
      if (!b)
      {
        std::vector<FileElement> feList;

        if (directory.toStdString() != "/") 
          feList.push_back({"..", "", "", "d"});

        int fileCount = 0, folderCount = 0;
        ParseDirectoryList(list, feList, &fileCount, &folderCount);
        m_fileCount = fileCount, m_folderCount = folderCount;

        std::partition(feList.begin(), feList.end(),
          [](const FileElement& e){ 
            return e.m_attributes[0] != '-';
          });

        QMetaObject::invokeMethod(this, [=](){
          beginResetModel();
          m_model.clear();
          m_model = feList;
          endResetModel();
          m_remoteDirectory = directory.toStdString();
          emit directoryList();
        }, Qt::QueuedConnection);
      }
      else
      {
        list.append(b, n);
      }
      return true;
    },
    [](const std::string& res) {
      if (res[0] == '4' || res[0] == '5') {
        STATUS(1) << "Error: " << res;
      }
    },
    m_protection);
}

QString FTPModel::getLocalDirectory(void)
{
  return QString::fromStdString(m_localDirectory);
}

void FTPModel::setLocalDirectory(QString directory)
{
  m_localDirectory = directory.toStdString();
}

QString FTPModel::getTotalFilesAndFolder(void)
{
  return QString::number(m_fileCount) + ":" + QString::number(m_folderCount);
}

void FTPModel::RefreshRemoteView(void)
{
  setRemoteDirectory(QString::fromStdString(m_remoteDirectory));
}

void FTPModel::ParseDirectoryList(const std::string& list, std::vector<FileElement>& feList, int *pfc, int *pdc)
{
  if (m_ftp->HasFeature("MLSD"))
    ParseMLSDList(list, feList, pfc, pdc);
  else if (m_ftp->SystemType().find("UNIX") != std::string::npos)
    ParseLinuxList(list, feList, pfc, pdc);
  else if (m_ftp->SystemType().find("Windows") != std::string::npos)
    ParseWindowsList(list, feList, pfc, pdc);
}

// type=file;size=8192;modify=20221219022112.389;perms=awr; DumpStack.log
// type=dir;modify=20221015170330.792;perms=cple; Intel
void FTPModel::ParseMLSDList(const std::string& list, std::vector<FileElement>& feList, int *pfc, int *pdc)
{
  auto lines = osl::split(list, "\r\n");

  for (auto& line : lines)
  {
    if (line.empty()) continue;

    std::string name;

    auto pos = line.rfind(';');

    if (pos != std::string::npos)
    {
      pos++;
      name = line.substr(pos);
      name = osl::trim(name, " ");
    }

    auto isDir = (line.find("type=dir") != std::string::npos);

    std::string size;

    if (!isDir)
    {
      auto pos = line.find("size=");

      if (pos != std::string::npos)
      {
        pos += strlen("size=");
        while (line[pos] != ';')
          size += line[pos++];
      }
    }

    if (pfc && pdc) isDir ? (*pdc += 1) : (*pfc += 1);

    feList.push_back({
      name, size, "",
      isDir ? "d" : "-", false});
  }
}

// -rw-rw-rw- 1 ftp    ftp       1468320 Oct 15 17:37 a b c
void FTPModel::ParseLinuxList(const std::string& list, std::vector<FileElement>& feList, int *pfc, int *pdc)
{
  auto lines = osl::split(list, "\r\n");

  for (auto& line : lines)
  {
    if (line.empty()) continue;

    FileElement fe;

    auto p = line.c_str();

    fe.m_attributes.append(p, 10), p += 10;

    auto isDir = (fe.m_attributes[0] == 'd');

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

    if (pfc && pdc) isDir ? (*pdc += 1) : (*pfc += 1);
  }
}

void FTPModel::ParseWindowsList(const std::string& list, std::vector<FileElement>& feList, int *pfc, int *pdc)
{
  LOG << list;

  auto lines = osl::split(list, "\r\n");

  for (auto& line : lines)
  {
    if (line.empty()) continue;

    auto p = line.c_str();

    while(*p != ' ') { p++; }
    while(*p == ' ') { p++; }
    while(*p != ' ') { p++; }
    while(*p == ' ') { p++; }

    auto isDir = (0 == memcmp(p, "<DIR>", strlen("<DIR>")));

    std::string size, name; 

    while(*p != ' ') {
      size.append(1, *p);
      p++;
    }

    while(*p == ' ') { p++; }

    name.append(p);

    if (pfc && pdc) isDir ? (*pdc += 1) : (*pfc += 1);

    feList.push_back({
      name, size, "",
      isDir ? "d" : "-", false});
  }
}
