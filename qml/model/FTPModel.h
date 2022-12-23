#ifndef FTPMODEL
#define FTPMODEL

#include <npl/npl>

#include <QAbstractListModel>

struct FileElement
{
  std::string m_name;
  std::string m_size;
  std::string m_timestamp;
  std::string m_attributes;
};

class FTPModel : public QAbstractListModel
{
  Q_OBJECT

  enum Roles
  {
    EFileName = Qt::UserRole,
    EFileSize,
    EFileIsDir,
    EFileAttributes
  };

  public:

  FTPModel();
  ~FTPModel();

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

  Q_PROPERTY(bool connected READ getConnected WRITE setConnected NOTIFY connected);
  Q_PROPERTY(QString currentDirectory READ getCurrentDirectory WRITE setCurrentDirectory);
  Q_PROPERTY(QString totalFilesAndFolders READ getTotalFilesAndFolder);

  Q_INVOKABLE bool InitConnect(QString host, QString port, QString user, QString password, QString protocol);

  signals:

  void connected(bool);
  void directoryList(void);

  public slots:

  bool getConnected(void);
  void setConnected(bool);

  QString getCurrentDirectory(void);
  void setCurrentDirectory(QString dir);
  QString getTotalFilesAndFolder(void);

  protected:

  auto ParseLinuxDirectoryList(const std::string& list) -> std::vector<FileElement>;

  int m_fileCount = 0;

  int m_folderCount = 0;

  bool m_connected = false;

  std::string m_currentDirectory;

  std::vector<FileElement> m_model;

  npl::SPProtocolFTP m_ftp;
};

#endif