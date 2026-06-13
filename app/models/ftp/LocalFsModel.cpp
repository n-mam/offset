#include <osl/singleton>
#include <LocalFsModel.h>
#include <RemoteFsModel.h>

#include <filesystem>

void LocalFsModel::QueueTransfers(bool start) {
    for (auto i = 0; i < m_model.size(); i++) {
        if (m_model[i].m_selected) {
            auto fileName = m_model[i].m_name;
            auto fileSize = GetElementSize(i);
            auto fileIsDir = IsElementDirectory(i);
            UploadInternal(
                fileName,
                m_currentDirectory,
                getInstance<RemoteFsModel>()->getCurrentDirectory().toStdString(),
                fileIsDir,
                fileSize);
        }
    }
}

void LocalFsModel::UploadInternal(const std::string& file, const std::string& localFolder, const std::string& remoteFolder, bool isFolder, uint64_t size) {
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
                            'I',
                            entry.file_size()});
                }
            }
        } else {
            getInstance<TransferManager>()->AddToTransferQueue({
                    localPath,
                    remotePath,
                    npl::ftp::upload,
                    'I',
                    size});
        }
    } catch(const std::exception& e) {
        LOG << e.what();
    }
}

void LocalFsModel::RemoveFile(QString path) {
    try {
        std::filesystem::remove(path.toStdString());
    }
    catch(const std::filesystem::filesystem_error& err) {
        LOG << "std::filesystem::remove exception : " << err.what();
    }
}

void LocalFsModel::RemoveDirectory(QString path) {
    try {
        std::filesystem::remove_all(path.toStdString());
    }
    catch(const std::filesystem::filesystem_error& err) {
        LOG << "std::filesystem::remove_all exception : " << err.what();
    }
}

void LocalFsModel::CreateDirectory(QString path) {
    try {
        std::filesystem::create_directory(path.toStdString());
    }
    catch(const std::exception& e) {
        LOG << e.what();
    }
}

void LocalFsModel::Rename(QString from, QString to) {
    try {
        std::filesystem::rename(from.toStdString(), to.toStdString());
    }
    catch(const std::exception& e) {
        LOG << e.what();
    }
}

void LocalFsModel::setCurrentDirectory(QString directory) {
    if (directory.isEmpty()) {
        directory = QString::fromStdString(
            std::filesystem::current_path().string());
    }
    m_currentDirectory = directory.toStdString();
    beginResetModel();
    m_model.clear();
    m_fileCount = m_folderCount = 0;
    m_model.push_back({"..", "", "", "d"});
    std::error_code ec;
    for (std::filesystem::directory_iterator entryIt(m_currentDirectory.utf8(), ec);
            !ec && entryIt != std::filesystem::end(entryIt); entryIt.increment(ec)) {
        if (ec) continue;
        const auto& entry = *entryIt;
        bool isDir = entry.is_directory(ec);
        if (ec) continue;
        isDir ? ++m_folderCount : ++m_fileCount;
        // get name safely
        auto u8name = entry.path().filename().u8string();
        std::string name(reinterpret_cast<const char*>(u8name.data()), u8name.size());
        // get file size safely
        std::string sizeStr = "0";
        if (!isDir) {
            std::uintmax_t fsize = entry.file_size(ec);
            if (!ec) sizeStr = std::to_string(fsize);
        }
        m_model.push_back({
            osl::string(name),
            sizeStr,
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