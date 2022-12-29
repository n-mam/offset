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
};

class TransferModel : public QAbstractListModel
{
  Q_OBJECT

  enum Roles
  {
    ELocal = Qt::UserRole,
    ERemote,
    EDirection,
    EType
  };

  public:

  TransferModel();
  ~TransferModel();

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

  void AddToTransferQueue(const Transfer& transfer);

  private:

  std::vector<Transfer> m_transfers;
};

#if defined _WIN32
constexpr char path_sep = '\\';
#else
constexpr char path_sep = '/';
#endif

#endif