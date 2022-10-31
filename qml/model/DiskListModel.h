#ifndef DiskListModel_HPP
#define DiskListModel_HPP

#include <memory>

#include <BaseModel.h>

struct BlockDevice : public BaseItem
{
  BlockDevice(
    QString name,
    int depth = 0,
    int children = 0,
    bool selectable = false,
    uint64_t size = 0,
    uint64_t free = 0) : 
  BaseItem(name, depth, children, selectable)
  {
    m_size = size;
    m_free = free;
  }
  uint64_t m_size = 0;
  uint64_t m_free = 0;
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

  enum Roles
  {
    ESize = BaseModel::ELastRole + 1,
    EFree
  };

  private:

};

#endif