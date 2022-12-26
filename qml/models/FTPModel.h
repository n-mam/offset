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
  bool m_selected = false;
};

using TRemoteWalkFileCallback = std::function<void (const std::string&)>;

class FTPModel : public QAbstractListModel
{
  Q_OBJECT

  enum Roles
  {
    EFileName = Qt::UserRole,
    EFileSize,
    EFileIsDir,
    ESelected,
    EFileAttributes
  };

  public:

  FTPModel();
  ~FTPModel();

  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
  bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;

  Q_PROPERTY(QString totalFilesAndFolders READ getTotalFilesAndFolder);
  Q_PROPERTY(bool connected READ getConnected WRITE setConnected NOTIFY connected);
  Q_PROPERTY(QString localDirectory WRITE setLocalDirectory);
  Q_PROPERTY(QString remoteDirectory READ getRemoteDirectory WRITE setRemoteDirectory);

  Q_INVOKABLE bool Connect(QString host, QString port, QString user, QString password, QString protocol);
  Q_INVOKABLE void Upload(QString path, bool isDir);
  Q_INVOKABLE void Download(QString remoteFolder, QString fileElement, bool isDirectory);
  Q_INVOKABLE void RemoveFile(QString path, bool local = false);
  Q_INVOKABLE void RemoveDirectory(QString path, bool local = false);
  Q_INVOKABLE void CreateDirectory(QString path, bool local = false);
  Q_INVOKABLE void Rename(QString from, QString to, bool local = false);
  Q_INVOKABLE void Quit();

  signals:

  void connected(bool);
  void directoryList(void);

  public slots:

  bool getConnected(void);
  void setConnected(bool);

  QString getTotalFilesAndFolder(void);
  void setLocalDirectory(QString dir);
  QString getRemoteDirectory(void);
  void setRemoteDirectory(QString dir);

  protected:

  void RefreshRemoteView(void);
  void WalkDirectory(const std::string& root, TRemoteWalkFileCallback callback);
  void ParseMLSDList(const std::string& list, std::vector<FileElement>& feList, int *pfc = nullptr, int * pdc = nullptr);
  auto ParseLinuxDirectoryList(const std::string& list) -> std::vector<FileElement>;

  int m_fileCount = 0;

  int m_folderCount = 0;

  bool m_connected = false;

  std::string m_localDirectory;

  std::string m_remoteDirectory;

  std::vector<FileElement> m_model;

  npl::SPProtocolFTP m_ftp;
};

#endif