#include <LocalFsModel.h>
#include <RemoteFsModel.h>

#include <filesystem>

LocalFsModel::LocalFsModel()
{
}

LocalFsModel::~LocalFsModel()
{
}

void LocalFsModel::QueueTransfer(int index, bool start)
{
  auto fileName = m_model[index].m_name;
  auto fileIsDir = IsElementDirectory(index);
  auto fileSize = GetElementSize(index);

  UploadInternal(
    fileName,
    m_currentDirectory,
    getInstance<RemoteFsModel>()->getCurrentDirectory().toStdString(),
    fileIsDir,
    fileSize);
}

void LocalFsModel::UploadInternal(const std::string& file, const std::string& localFolder, const std::string& remoteFolder, bool isFolder, uint64_t size)
{
  auto localPath = localFolder + ((localFolder.back() == path_sep) ? file : (path_sep + file));
  auto remotePath = remoteFolder + ((remoteFolder.back() == '/') ? file : ("/" + file));

  try {
    if (isFolder) {
      for (auto const& entry : std::filesystem::directory_iterator(localPath)) {
        if (entry.is_directory()) {
          UploadInternal(
            entry.path().filename().string(),
            localPath,
            remotePath,
            true);
        } else if (entry.is_regular_file()) {
          getInstance<TransferManager>()->AddToTransferQueue({
            entry.path().string(),
            remotePath + "/" + entry.path().filename().string(),
            npl::ftp::upload,
            'I', entry.file_size()
          });
        }
      }
    } else {
      getInstance<TransferManager>()->AddToTransferQueue({
        localPath,
        remotePath,
        npl::ftp::upload,
        'I', size
      });
    }
  }
  catch(const std::exception& e) {
    LOG << e.what();
  }
}

void LocalFsModel::RemoveFile(QString path)
{
  try {
    std::filesystem::remove(path.toStdString());
  }
  catch(const std::filesystem::filesystem_error& err) {
    LOG << "std::filesystem::remove exception : " << err.what();
  }
}

void LocalFsModel::RemoveDirectory(QString path)
{
  try {
    std::filesystem::remove_all(path.toStdString());
  }
  catch(const std::filesystem::filesystem_error& err) {
    LOG << "std::filesystem::remove_all exception : " << err.what();
  }
}

void LocalFsModel::CreateDirectory(QString path)
{
  try {
    std::filesystem::create_directory(path.toStdString());
  }
  catch(const std::exception& e) {
    LOG << e.what();
  }
}

void LocalFsModel::Rename(QString from, QString to)
{
  try {
    std::filesystem::rename(from.toStdString(), to.toStdString());
  }
  catch(const std::exception& e) {
    LOG << e.what();
  }
}

void LocalFsModel::setCurrentDirectory(QString directory)
{
  if (directory.isEmpty())
    directory = QString::fromStdString(
      std::filesystem::current_path().string());

  m_currentDirectory = directory.toStdString();

  beginResetModel();

  m_model.clear();

  m_fileCount = m_folderCount = 0;

  m_model.push_back({"..", "", "", "d"});

  for (auto& entry : std::filesystem::directory_iterator(m_currentDirectory))
  {
    auto isDir = std::filesystem::is_directory(entry);

    isDir ? m_folderCount++ : m_fileCount++;

    m_model.push_back({
      entry.path().filename().string(),
      (entry.is_regular_file() ? std::to_string(entry.file_size()) : "0"),
      "",
      (isDir ? "d" : "-"),
      false
    });
  }

  std::ranges::partition(m_model, [](const auto& e) {
      return e.m_attributes[0] == 'd';
  });

  emit directoryList();

  endResetModel();
}
