#include <DiskListModel.h>

DiskListModel::DiskListModel()
{
  m_model.push_back(std::make_shared<BlockDevice>("PhysicalDrive0", 0, 2));
  m_model.push_back(std::make_shared<BlockDevice>("C:\\", 1, 1, true, 300, 100));
  m_model.push_back(std::make_shared<BlockDevice>("\\\\?\\HarddiskVolumeShadowCopy2", 2, 0, true, 300, 50));  
  m_model.push_back(std::make_shared<BlockDevice>("C:\\mount_point\\1", 1, 0, true, 500, 125));
  m_model.push_back(std::make_shared<BlockDevice>("PhysicalDrive1", 0, 1));
  m_model.push_back(std::make_shared<BlockDevice>("E:\\", 1, 0, true));
  m_model.push_back(std::make_shared<BlockDevice>("PhysicalDrive2", 0, 2));
  m_model.push_back(std::make_shared<BlockDevice>("F:\\", 1, 0, true));
  m_model.push_back(std::make_shared<BlockDevice>("G:\\", 1, 0, true));
}

DiskListModel::~DiskListModel()
{
}

QHash<int, QByteArray> DiskListModel::roleNames() const
{
  QHash<int, QByteArray> roles = BaseModel::roleNames();
  roles.insert(ESize, "sizeRole");
  roles.insert(EFree, "freeRole");
  roles.insert(EDepth, "depthRole");
  roles.insert(ESelectable, "selectableRole");
  roles.insert(EHasChildren, "hasChildrenRole");
  roles.insert(Qt::ForegroundRole, "textColorRole");
  return roles;
}

QVariant DiskListModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  auto row = index.row();
  auto column = index.column();

  switch (role)
  {
    case ESize:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return (std::static_pointer_cast<BlockDevice>(m_model[row]))->m_size;
      }
      break;
    }

    case EFree:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return (std::static_pointer_cast<BlockDevice>(m_model[row]))->m_free;
      }
      break;
    }

    default:
      return BaseModel::data(index, role);
  }

  return QVariant();
}