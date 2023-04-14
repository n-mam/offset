#include <LocalFsModel.h>
#include <RemoteFsModel.h>

RemoteFsModel::RemoteFsModel()
{
}

RemoteFsModel::~RemoteFsModel()
{
}

RemoteFsModel * RemoteFsModel::getInstance(void)
{
  static RemoteFsModel * s_instance = new RemoteFsModel();
  return s_instance;
}

bool RemoteFsModel::Connect(QString host, QString port, QString user, QString password, QString protocol)
{
  m_port = port.toInt();
  m_host = host.toStdString();
  m_user = user.toStdString();
  m_password = password.toStdString();

  m_protection = (protocol == "FTPS") ? npl::tls::yes : npl::tls::no;

  m_ftp = npl::make_ftp(m_host, m_port , m_protection);

  if (m_ftp) {
    m_ftp->SetIdleCallback([this](){
      QMetaObject::invokeMethod(this, [=](){
        for (auto rit = m_directories_to_remove.rbegin(); 
              rit != m_directories_to_remove.rend(); rit++)
          m_ftp->RemoveDirectory(*rit);
        if (!m_directories_to_remove.empty()) {
          m_directories_to_remove.clear();
          RefreshRemoteView();
        }
      });
    });

    m_ftp->SetCredentials(m_user, m_password,
      [this](bool success){
        QMetaObject::invokeMethod(this, [=](){
          if (success) {
            setCurrentDirectory("/");
            STATUS(1) << "User " << m_user << " logged in";
          } else {
            STATUS(1) << "Login failed";
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

  STATUS(1) << "Failed to connect to " << m_host;

  return false;
}

void RemoteFsModel::QueueTransfer(int index, bool start)
{
  auto fileName = m_model[index].m_name;
  auto fileIsDir = IsElementDirectory(index);
  auto fileSize = GetElementSize(index);

  DownloadInternal(
    fileName,
    m_currentDirectory,
    LocalFsModel::getInstance()->getCurrentDirectory().toStdString(),
    fileIsDir,
    fileSize);
}

void RemoteFsModel::DownloadInternal(const std::string& file, const std::string& folder, const std::string& localFolder, bool isFolder, uint64_t size)
{
  auto remotePath = folder + ((folder.back() == '/') ? file : ("/" + file));
  auto localPath = localFolder + ((localFolder.back() == path_sep) ? file : (path_sep + file));

  if (isFolder) {
    WalkRemoteDirectory(remotePath, [=](const std::vector<FileElement>& fe_list){
      for (const auto& fe : fe_list)
        if (fe.m_attributes[0] == 'd') {
          DownloadInternal(
            fe.m_name,
            remotePath,
            localPath,
            true);
        } else {
          TransferManager::getInstance()->AddToTransferQueue({
            localPath + path_sep + fe.m_name,
            remotePath + "/" + fe.m_name,
            npl::ftp::download,
            'I', std::stoull(fe.m_size)
          });
        }
    });
  } else {
    TransferManager::getInstance()->AddToTransferQueue({
      localPath,
      remotePath,
      npl::ftp::download,
      'I', size
    });
  }
}

void RemoteFsModel::WalkRemoteDirectory(const std::string& path, TFileElementListCallback callback)
{
  m_ftp->Transfer(npl::ftp::list, path,
    [=, list = std::string()] (const char *b, size_t n) mutable {
      if (b)
      {
        list.append(b, n);
      }
      else
      {
        std::vector<FileElement> fe_list;
        ParseDirectoryList(list, fe_list);
        callback(fe_list);
      }
      return true;
    }, nullptr, m_protection);
}

void RemoteFsModel::RemoveFile(QString path)
{
  m_ftp->RemoveFile(path.toStdString());
}

void RemoteFsModel::RemoveDirectory(QString path)
{
  WalkRemoteDirectory(path.toStdString(),
    [=](const std::vector<FileElement>& fe_list) {
      bool onlyFiles = true;
      for (const auto& fe : fe_list) {
        auto fe_path = path + ((path.back() == '/') ? 
            QString::fromStdString(fe.m_name) : ("/" + QString::fromStdString(fe.m_name)));
        if (fe.m_attributes[0] == 'd') {
          onlyFiles = false;
          RemoveDirectory(fe_path);
        }
        else {
          RemoveFile(fe_path);
        }
      }
      if (fe_list.empty() || onlyFiles) {
        m_ftp->RemoveDirectory(path.toStdString(),
          [](const std::string& res) { STATUS(1) << res; });
      } else {
        m_directories_to_remove.push_back(path.toStdString());
      }
    });
}

void RemoteFsModel::CreateDirectory(QString path)
{
  m_ftp->CreateDirectory(path.toStdString(),
    [](const std::string& res) { STATUS(1) << res; });
  RefreshRemoteView();
}

void RemoteFsModel::Rename(QString from, QString to)
{
  m_ftp->Rename(from.toStdString(), to.toStdString(),
    [](const std::string& res) {
      if (res[0] == '4' || res[0] == '5')
        STATUS(1) << "Error: " << res;
    });
  RefreshRemoteView();
}

void RemoteFsModel::Quit()
{
  m_ftp->Quit();
}

bool RemoteFsModel::getConnected(void)
{
  return m_connected;
}

void RemoteFsModel::setConnected(bool isConnected)
{
  if (m_connected != isConnected)
  {
    m_connected = isConnected;
    emit connected(m_connected);
    STATUS(1) << (isConnected ? "Connected to " : 
      "Disconnected from ") << m_host;
  }
}

void RemoteFsModel::setCurrentDirectory(QString directory)
{
  m_ftp->SetCurrentDirectory(directory.toStdString());

  m_ftp->Transfer(npl::ftp::list, directory.toStdString(),
    [=, list = std::string()] (const char *b, size_t n) mutable {
      if (!b)
      {
        std::vector<FileElement> fe_list;

        if (directory.toStdString() != "/")
          fe_list.push_back({"..", "", "", "d"});

        int fileCount = 0, folderCount = 0;
        ParseDirectoryList(list, fe_list, &fileCount, &folderCount);
        m_fileCount = fileCount, m_folderCount = folderCount;

        std::partition(fe_list.begin(), fe_list.end(),
          [](const auto& e){
            return e.m_attributes[0] == 'd';
          });

        QMetaObject::invokeMethod(this, [=](){
          beginResetModel();
          m_model.clear();
          m_model = fe_list;
          endResetModel();
          m_currentDirectory = directory.toStdString();
          emit directoryList();
          STATUS(1) << "Directory listing successful";
        }, Qt::QueuedConnection);
      }
      else
      {
        list.append(b, n);
      }
      return true;
    },
    [this](const std::string& res) {
      QMetaObject::invokeMethod(this, [=](){
        if (res[0] == '4' || res[0] == '5')
          STATUS(1) << "Error: " << res;
      }, Qt::QueuedConnection);
    },
    m_protection);
}

void RemoteFsModel::RefreshRemoteView(void)
{
  setCurrentDirectory(QString::fromStdString(m_currentDirectory));
}

void RemoteFsModel::ParseDirectoryList(const std::string& list, std::vector<FileElement>& fe_list, int *pfc, int *pdc)
{
  if (m_ftp->HasFeature("MLSD"))
    ParseMLSDList(list, fe_list, pfc, pdc);
  else if (m_ftp->SystemType().find("UNIX") != std::string::npos)
    ParseLinuxList(list, fe_list, pfc, pdc);
  else if (m_ftp->SystemType().find("Windows") != std::string::npos)
    ParseWindowsList(list, fe_list, pfc, pdc);
}

// type=file;size=8192;modify=20221219022112.389;perms=awr; DumpStack.log
// type=dir;modify=20221015170330.792;perms=cple; Intel
void RemoteFsModel::ParseMLSDList(const std::string& list, std::vector<FileElement>& fe_list, int *pfc, int *pdc)
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

    fe_list.push_back({
      name, size, "",
      isDir ? "d" : "-", false});
  }
}

// -rw-rw-rw- 1 ftp    ftp       1468320 Oct 15 17:37 a b c
void RemoteFsModel::ParseLinuxList(const std::string& list, std::vector<FileElement>& fe_list, int *pfc, int *pdc)
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

    fe_list.push_back(fe);

    if (pfc && pdc) isDir ? (*pdc += 1) : (*pfc += 1);
  }
}

void RemoteFsModel::ParseWindowsList(const std::string& list, std::vector<FileElement>& fe_list, int *pfc, int *pdc)
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

    fe_list.push_back({
      name, size, "",
      isDir ? "d" : "-", false});
  }
}
