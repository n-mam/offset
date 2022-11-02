#ifndef DISKLISTMODEL_HPP
#define DISKLISTMODEL_HPP

#include <memory>
#include <future>

#include <BaseModel.h>

struct BlockDevice : public BaseItem
{
  BlockDevice(
    QString name,
    int depth = 0,
    int children = 0,
    bool selectable = false,
    double size = 0,
    double free = 0) : 
  BaseItem(name, depth, children, selectable)
  {
    m_size = size;
    m_free = free;
  }
  double m_size = 0;
  double m_free = 0;
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

  Q_INVOKABLE void ConvertSelectedItemsToVirtualDisks(QString folder);

  Q_PROPERTY(bool transfer READ getTransfer WRITE setTransfer NOTIFY transferChanged);

  enum Roles
  {
    ESize = BaseModel::ELastRole + 1,
    EFree
  };

  public slots:

  bool getTransfer() const;
  void setTransfer(bool);

  private:

  bool transfer = false;
  std::vector<std::future<void>> futures;

  signals:

  void transferChanged(bool);
  void progress(QString, int);
};

#endif