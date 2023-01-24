#ifndef TRANSFERMANAGER
#define TRANSFERMANAGER

#include <atomic>

#include <npl/npl>

#include <QAbstractListModel>

struct Transfer
{
  std::string m_local;
  std::string m_remote;
  npl::ftp::Direction m_direction;
  char m_type;
  uint64_t m_size = 0;

  enum state : uint8_t {
    queued = 0,
    processing,
    cancelled,
    failed,
    successful
  };

  int m_sid = 0;
  int m_index = -1;
  int m_progress = 0;
  mutable state m_state = queued;
};

class FTPModel;

constexpr size_t MAX_SESSIONS = 2;

class TransferManager : public QAbstractListModel
{
  Q_OBJECT

  public:

  enum Roles
  {
    ELocal = Qt::UserRole,
    ERemote,
    EDirection,
    EType,
    EProgress
  };

  TransferManager(FTPModel *ftpModel);
  ~TransferManager();

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

  void AddToTransferQueue(const Transfer& transfer);

  Q_INVOKABLE void StopAllTransfers(void);
  Q_INVOKABLE void ProcessAllTransfers(void);
  Q_INVOKABLE void ProcessTransfer(int row, int sid, bool oneoff);
  Q_INVOKABLE void RemoveAllTransfers(void);
  Q_INVOKABLE void RemoveTransfer(int row);

  public slots:

  void TransferFinished(int i);

  signals:

  void activeTransfers(int count);
  void transferCancelled(int index);
  void transferStarted(int index);
  void transferQueueSize(int count);
  void transferSuccessful(int index, int count);
  void transferFailed(int index, int count);

  private:

  bool UserCancelled(void);
  bool OneOffTransfer(void);
  bool InitializeFTPSessions(void);
  void CheckAndReconnectSessions(void);
  int GetSessionWithLeastQueueDepth(void);
  void DownloadTransfer(const Transfer& t, int sid);
  void UploadTransfer(const Transfer& t, int sid);

  FTPModel *m_ftpModel;

  std::vector<Transfer> m_queue;

  std::vector<npl::SPProtocolFTP> m_sessions;

  int m_next_session = 0;

  int m_activeTransfers = 0;

  int m_failed_transfers = 0;

  int m_successful_transfers = 0;

  bool m_one_off = false;

  std::atomic<bool> m_stop{false};
};

#if defined _WIN32
constexpr char path_sep = '\\';
#else
constexpr char path_sep = '/';
#endif

#endif