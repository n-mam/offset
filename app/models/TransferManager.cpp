#include <osl/singleton>
#include <RemoteFsModel.h>
#include <TransferManager.h>

TransferManager::TransferManager() {
    m_queue.reserve(4096);
    m_ftpModel = getInstance<RemoteFsModel>();
    connect(this, &TransferManager::transferFailed, this, &TransferManager::TransferFinished);
    connect(this, &TransferManager::transferCancelled, this, &TransferManager::TransferFinished);
    connect(this, &TransferManager::transferSuccessful, this, &TransferManager::TransferFinished);
}

TransferManager::~TransferManager(){}

QHash<int, QByteArray> TransferManager::roleNames() const {
    auto roles = QAbstractListModel::roleNames();
    roles.insert(ELocal, "local");
    roles.insert(ERemote, "remote");
    roles.insert(EDirection, "direction");
    roles.insert(EType, "type");
    roles.insert(EProgress, "progress");
    return roles;
}

int TransferManager::rowCount(const QModelIndex& parent) const {
    return static_cast<int>(m_queue.size());
}

QVariant TransferManager::data(const QModelIndex& index, int role) const {
    if (!index.isValid()) {
        return QVariant();
    }
    auto row = index.row();
    switch (role) {
        case ELocal: {
            return QString::fromStdString(m_queue[row].m_local);
        }
        case ERemote: {
            return QString::fromStdString(m_queue[row].m_remote);
        }
        case EDirection: {
            return (int)(m_queue[row].m_direction);
        }
        case EType: {
            return m_queue[row].m_type;
        }
        case EProgress: {
            return m_queue[row].m_progress;
        }
        default:
            break;
    }
    return QVariant();
}

void TransferManager::AddToTransferQueue(const Transfer& transfer) {
    QMetaObject::invokeMethod(this,
        [this, t = std::move(transfer)]() mutable {
            auto pos = m_queue.size();
            beginInsertRows(QModelIndex(), pos, pos);
            m_queue.emplace_back(t);
            endInsertRows();
            emit transferQueueSize(m_queue.size());
        });
}

int TransferManager::GetSessionWithLeastQueueDepth(void) {
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

bool TransferManager::UserCancelled(void) {
    return m_stop.load(std::memory_order_relaxed);
}

bool TransferManager::OneOffTransfer(void) {
    return m_one_off;
}

void TransferManager::StopAllTransfers(void) {
    if (m_activeTransfers) {
        STATUS(1) << "Stopping all transfers..";
        m_stop.store(true, std::memory_order_relaxed);
    } else {
        STATUS(1) << "No active transfers";
    }
}

void TransferManager::TransferFinished(int i) {
    emit activeTransfers(--m_activeTransfers);
    if (UserCancelled() || OneOffTransfer()) {
        if (!m_activeTransfers) {
            auto status = UserCancelled() ?
            "Transfer cancelled" : "Transfer finished";
            STATUS(1) << status;
        }
        return;
    }
    for (int j = i + 1; j < m_queue.size(); j++) {
        if (m_queue[j].m_state == Transfer::state::queued) {
            ProcessTransfer(j, m_queue[i].m_sid, false);
            break;
        }
    }
}

void TransferManager::ProcessAllTransfers(void) {
    auto limit = std::min(MAX_SESSIONS, m_queue.size());
    if (!limit) {
        STATUS(1) << "Transfer queue empty";
    }
    for (int i = 0; i < limit; i++) {
        ProcessTransfer(i, m_next_session, false);
        m_next_session = (m_next_session + 1) % MAX_SESSIONS;
    }
}

void TransferManager::ProcessTransfer(int row, int sid, bool oneoff) {
    Transfer& t = m_queue[row];
    if (t.m_state == Transfer::state::queued) {
        static bool b = InitializeFTPSessions();
        b ? b = false : (CheckAndReconnectSessions(), false);
        t.m_sid = (sid >= 0) ? sid : GetSessionWithLeastQueueDepth();
        t.m_index = row;
        m_one_off = oneoff;
        emit transferStarted(t.m_index);
        emit activeTransfers(++m_activeTransfers);
        t.m_state = Transfer::state::processing;
        m_stop.store(false, std::memory_order_relaxed);
        STATUS(1) << "Transfer in progress..";
        if (t.m_direction == npl::ftp::download) {
            DownloadTransfer(t, t.m_sid);
        } else if (t.m_direction == npl::ftp::upload) {
            UploadTransfer(t, t.m_sid);
        }
    }
}

void TransferManager::DownloadTransfer(const Transfer& t, int sid) {
    std::filesystem::path path = t.m_local;
    std::filesystem::create_directories(path.parent_path());
    auto file = std::make_shared<npl::file_device>(t.m_local, true);
    auto& ftp = m_sessions[sid];
    ftp->Transfer(t.m_direction, t.m_remote,
        [=, this, i = t.m_index, offset = 0ULL]
        (const char *b, size_t n) mutable {
            if (UserCancelled()) {
                if (!b) {
                    QMetaObject::invokeMethod(this, [=, this](){
                        m_queue[i].m_state = Transfer::state::cancelled;
                        emit transferCancelled(i);
                    });
                }
                return false;
            }

            if (b) {
                file->Write((uint8_t *)b, n, offset);
                offset += n;
            } else {
                if (m_queue[i].m_state != Transfer::state::successful) {
                    file.reset();
                    QMetaObject::invokeMethod(this, [=, this](){
                        m_queue[i].m_state = Transfer::state::successful;
                        emit transferSuccessful(i, ++m_successful_transfers);
                    });
                }
            }

            auto& tt = m_queue[i];
            if (tt.m_size) {
                int p = b ? (((float)offset / tt.m_size) * 100) : 100;
                if (p > tt.m_progress) {
                    tt.m_progress = p;
                    QMetaObject::invokeMethod(this, [=, this](){
                        emit dataChanged(index(i), index(i), {Roles::EProgress});
                    });
                }
            }

            return true;
        },
        [=, this, i = t.m_index](const auto& res) {
            if (res[0] == '4' || res[0] == '5') {
                QMetaObject::invokeMethod(this, [=, this](){
                    m_queue[i].m_state = Transfer::state::failed;
                    emit transferFailed(i, ++m_failed_transfers);
                });
            }
        },
        m_ftpModel->m_protection);
}

void TransferManager::UploadTransfer(const Transfer& t, int sid) {
    std::filesystem::path path = t.m_remote;
    auto& ftp = m_sessions[sid];
    std::string directory;
    auto tokens = osl::split<std::string>(path.parent_path().string(), "/");
    for (const auto& e : tokens) {
        if (!e.empty()) {
            directory += "/" + e;
            ftp->CreateDirectory(directory);
        }
    }
    auto file = std::make_shared<npl::file_device>(t.m_local, false);
    uint8_t *buf = (uint8_t *) calloc(1, _1M);

    ftp->Transfer(t.m_direction, t.m_remote,
        [=, this, i = t.m_index, offset = 0ULL]
        (const char *b, size_t l) mutable {
        if (UserCancelled()) {
            if (!b) {
                QMetaObject::invokeMethod(this, [=, this](){
                    m_queue[i].m_state = Transfer::state::cancelled;
                    emit transferCancelled(i);
                });
            }
            return false;
        }

        int32_t n = 0;

        if (b) {
            n = file->ReadSync(buf, _1M, offset);
            if (n) {
                ftp->Write(buf, n);
                offset += n;
            }
        } else {
            if (m_queue[i].m_state != Transfer::state::successful) {
                QMetaObject::invokeMethod(this, [=, this](){
                    m_queue[i].m_state = Transfer::state::successful;
                    emit transferSuccessful(i, ++m_successful_transfers);
                });
            }
        }

        auto& tt = m_queue[i];

        if (tt.m_size) {
            int p = b ? (((float)offset / tt.m_size) * 100) : 100;
            if (p > tt.m_progress) {
                tt.m_progress = p;
                QMetaObject::invokeMethod(this, [=, this](){
                    emit dataChanged(index(i), index(i), {Roles::EProgress});
                });
            }
        }

        return (n > 0);
        },
        [=, this, i = t.m_index](const auto& res) {
            if (res[0] == '4' || res[0] == '5') {
                QMetaObject::invokeMethod(this, [=, this](){
                    m_queue[i].m_state = Transfer::state::failed;
                    emit transferFailed(i, ++m_failed_transfers);
                });
            }
        },
        m_ftpModel->m_protection);
}

void TransferManager::RemoveAllTransfers(void) {
    if (!m_activeTransfers) {
        if (m_queue.size()) {
            beginResetModel();
            m_queue.clear();
            emit transferQueueSize(0);
            m_activeTransfers = 0;
            m_failed_transfers = 0;
            m_successful_transfers = 0;
            endResetModel();
        }
    }
}

void TransferManager::RemoveTransfer(int row) {
    if (!m_activeTransfers) {
        beginRemoveRows(QModelIndex(), row, row);
        m_queue.erase(m_queue.begin() + row);
        emit transferQueueSize(static_cast<int>(m_queue.size()));
        endRemoveRows();
    }
}

bool TransferManager::InitializeFTPSessions(void) {
    while(m_sessions.size() != MAX_SESSIONS) {
        auto ftp = npl::make_ftp(
            m_ftpModel->m_host,
            m_ftpModel->m_port,
            m_ftpModel->m_protection);
        if (!ftp) {
            STATUS(1) << "Failed to connect to " << m_ftpModel->m_host;
            return false;
        }
        ftp->SetCredentials(m_ftpModel->m_user, m_ftpModel->m_password);
        ftp->StartClient([this](auto p, bool isConnected){
            if (!isConnected) {}
        });
        m_sessions.push_back(ftp);
    }
    return true;
}

void TransferManager::CheckAndReconnectSessions(void) {
    for (size_t i = 0; i < MAX_SESSIONS; i++) {
        if (!m_sessions[i]->is_connected()) {
            m_sessions[i] = npl::make_ftp(
                m_ftpModel->m_host,
                m_ftpModel->m_port,
                m_ftpModel->m_protection);
            m_sessions[i]->SetCredentials(m_ftpModel->m_user, m_ftpModel->m_password);
            m_sessions[i]->StartClient(
                [this](auto p, bool isConnected){
                    if (!isConnected) { }
                });
        }
    }
}