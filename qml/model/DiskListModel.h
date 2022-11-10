#ifndef DISKLISTMODEL_HPP
#define DISKLISTMODEL_HPP

#include <memory>
#include <future>

#include <BaseModel.h>

struct BlockDevice : public BaseItem
{
  BlockDevice(
    QVector<QString> names,
    int depth = 0,
    int children = 0,
    double size = 0,
    double free = 0) :
  BaseItem(names, depth, children)
  {
    m_size = size;
    m_free = free;
  }
  bool isDisk = false;
  int m_disk = -1;
  QString m_fs;
  double m_size = 0;
  double m_free = 0;
  QString m_label;
  unsigned long m_serial = 0;
  bool m_vss = true;
  QString m_type = "vhd-d";
};

using SPBlockDevice = std::shared_ptr<BlockDevice>;

class DiskListModel : public BaseModel
{
  Q_OBJECT  
  
  public:

  DiskListModel();
  ~DiskListModel();

  QHash<int, QByteArray> roleNames() const override;
  QVariant data(const QModelIndex &index, int role) const override;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
  
  Q_INVOKABLE void ConvertSelectedItemsToVirtualDisks(QString folder);

  Q_PROPERTY(bool stop READ getStop WRITE setStop);
  Q_PROPERTY(bool transfer READ getTransfer WRITE setTransfer NOTIFY transferChanged);

  enum Roles
  {
    ESize = BaseModel::ELastRole + 1,
    EFree,
    EVSS,
    EType,
    EMetaData
  };

  public slots:

  bool getTransfer() const;
  void setTransfer(bool);
  bool getStop() const;
  void setStop(bool);
  void RefreshModel() override;

  private:

  bool transfer = false;
  bool stop = false;
  std::vector<std::future<void>> m_futures;

  signals:

  void transferChanged(bool);
  void progress(QString, int);
};

#endif