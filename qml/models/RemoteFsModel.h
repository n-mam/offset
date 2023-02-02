#ifndef FTPMODEL
#define FTPMODEL

#include <npl/npl>

#include <FsModel.h>

#include <QAbstractListModel>

using TFileElementListCallback = std::function<void (const std::vector<FileElement>&)>;

class RemoteFsModel : public FsModel
{
  Q_OBJECT

  public:

  RemoteFsModel();
  ~RemoteFsModel();

  static RemoteFsModel * getInstance(void);

  Q_PROPERTY(bool connected READ getConnected WRITE setConnected NOTIFY connected);

  Q_INVOKABLE void Quit();
  Q_INVOKABLE bool Connect(QString host, QString port, QString user, QString password, QString protocol);

  Q_INVOKABLE virtual void QueueTransfer(int index) override;
  Q_INVOKABLE virtual void RemoveFile(QString path) override;
  Q_INVOKABLE virtual void RemoveDirectory(QString path) override;
  Q_INVOKABLE virtual void CreateDirectory(QString path) override;
  Q_INVOKABLE virtual void Rename(QString from, QString to) override;

  int m_port;
  std::string m_host;
  std::string m_user;
  std::string m_password;
  std::string m_protocol;

  npl::tls m_protection = npl::tls::yes;

  signals:

  void connected(bool);

  public slots:

  bool getConnected(void);
  void setConnected(bool);

  virtual void setCurrentDirectory(QString) override;

  protected:

  void RefreshRemoteView(void);
  void WalkRemoteDirectory(const std::string& path, TFileElementListCallback callback);
  void DownloadInternal(const std::string& file, const std::string& folder, const std::string& localFolder, bool isFolder, uint64_t size = 0);

  void ParseDirectoryList(const std::string& list, std::vector<FileElement>& feList, int *pfc = nullptr, int *pdc = nullptr);
  void ParseMLSDList(const std::string& list, std::vector<FileElement>& feList, int *pfc = nullptr, int * pdc = nullptr);
  void ParseWindowsList(const std::string& list, std::vector<FileElement>& feList, int *pfc = nullptr, int *pdc = nullptr);
  void ParseLinuxList(const std::string& list, std::vector<FileElement>& feList, int *pfc = nullptr, int *pdc = nullptr);
  
  bool m_connected = false;

  npl::SPProtocolFTP m_ftp;

  std::vector<std::string> m_directories_to_remove;
};

#endif