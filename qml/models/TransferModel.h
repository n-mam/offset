#ifndef TRANSFERMODEL
#define TRANSFERMODEL

#include <npl/npl>

#include <QAbstractListModel>

struct Transfer
{
  std::string m_local;
  std::string m_remote;
  npl::ProtocolFTP::EDirection m_direction;
  char m_type;
  uint64_t m_size = 0;
  int m_progress = 0;
  int m_index = -1;
  bool m_done = false;
};

class FTPModel;

constexpr size_t MAX_SESSIONS = 1;

class TransferModel : public QAbstractListModel
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

  TransferModel(FTPModel *ftpModel);
  ~TransferModel();

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

  void AddToTransferQueue(const Transfer& transfer);

  Q_INVOKABLE void ProcessAllTransfers(void);
  Q_INVOKABLE void ProcessTransfer(int row = -1);
  Q_INVOKABLE void RemoveAllTransfers(void);
  Q_INVOKABLE void RemoveTransfer(int row = -1);

  public slots:

  signals:

  void transferDone(int);

  private:

  void DownloadTransfer(const Transfer& t);
  void UploadTransfer(const Transfer& t);
  bool InitializeFTPSessions(void);
  void CheckAndReconnectSessions(void);

  FTPModel *m_ftpModel;

  std::vector<Transfer> m_queue;

  std::vector<npl::SPProtocolFTP> m_sessions;

  int m_next_session = 0;

  int m_successful_transfers = 0;  
};

#if defined _WIN32
constexpr char path_sep = '\\';
#else
constexpr char path_sep = '/';
#endif

#endif