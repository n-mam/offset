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
};

class FTPModel;

constexpr int MAX_SESSIONS = 1;

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

  void AddToTransferQueue(Transfer&& transfer);

  private:

  void ProcessTransfer(Transfer&);

  void CreateFTPSession(void);

  FTPModel *m_ftpModel;

  std::vector<Transfer> m_queue;

  std::vector<npl::SPProtocolFTP> m_sessions;

  int m_next_session = 0;
};

#if defined _WIN32
constexpr char path_sep = '\\';
#else
constexpr char path_sep = '/';
#endif

#endif