#include <QJSEngine>

#include <fxc/fxc>

#include <DiskListModel.h>

DiskListModel::DiskListModel()
{
  npl::make_dispatcher();
  RefreshModel();
}

DiskListModel::~DiskListModel()
{
}

QHash<int, QByteArray> DiskListModel::roleNames() const
{
  QHash<int, QByteArray> roles = BaseModel::roleNames();
  roles.insert(ESize, "sizeRole");
  roles.insert(EFree, "freeRole");
  roles.insert(EMetaData, "metaDataRole");
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
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_size;
      }
      break;
    }

    case EFree:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_free;
      }
      break;
    }

    case EMetaData:
    {
      if (column == 0 && !index.parent().isValid())
      {
        auto bd = std::static_pointer_cast<BlockDevice>(m_model[row]);
        if (bd->isDisk)
          return QVector<QString>({"MBR", "Basic"});
        else
          return QVector<QString>({bd->m_fs, bd->m_label, QString::number(bd->m_serial)});
      }
      break;
    }

    default:
      return BaseModel::data(index, role);
  }

  return QVariant();
}

bool DiskListModel::getTransfer() const
{
  return transfer;
}

void DiskListModel::setTransfer(bool current)
{
  if (transfer != current)
  {
    transfer = current;
    emit transferChanged(transfer);
  }
}

bool DiskListModel::getStop() const
{
  return this->stop;
}

void DiskListModel::setStop(bool stop)
{
  this->stop = stop;
}

void DiskListModel::ConvertSelectedItemsToVirtualDisks(QString folder)
{
  setTransfer(true);

  auto selected = getSelectedItems();

  std::vector<fxc::TBackupConfig> configuration;

  for (auto& selection : selected)
  {
    auto names = ((qjsEngine(this))->toScriptValue(selection)).property(0);
    auto type = ((qjsEngine(this))->toScriptValue(selection)).property(1).toString();
    auto vss = ((qjsEngine(this))->toScriptValue(selection)).property(2).toString();

    QString name;

    if (names.property("length").toInt() == 1) 
      name = names.property(0).toString();
    else
      name = names.property(1).toString();

    LOG << name.toStdWString() << L", " << type.toStdWString() << L", " << vss.toStdWString();

    configuration.push_back({
      name.toStdWString(), 
      L"0",
      folder.toStdWString(),
      type.toStdWString(),
      L"",
      (vss == "live")
    });
  }

  m_futures.push_back(std::async(std::launch::async, 
    [this, configuration](){
      fxc::ConvertBlockDeviceToVirtualImages(configuration, 
        [this](auto device, auto percent){
          QMetaObject::invokeMethod(this, [this, device, percent](){
            emit this->progress(QString::fromStdWString(device), percent);
          }, Qt::QueuedConnection);
          return this->stop;
        });
      this->setTransfer(false);
      this->setStop(false);
    }
  ));
}

void DiskListModel::RefreshModel()
{
  beginResetModel();
  
  m_model.clear();

  auto volumes = osl::EnumerateVolumes();

  auto snapshots = fxc::EnumerateSnapshots();

  for (auto& names : volumes)
  {
    QVector<QString> children; 

    for (const auto& ss : snapshots)
    {
      if (std::get<1>(ss) == names.front())
      {
        auto tokens = osl::wsplit(std::get<0>(ss), L"GLOBALROOT\\Device\\");
        auto childlabel = QString::fromWCharArray((tokens[0] + tokens[1]).c_str());
        children.push_back(childlabel);
      }
    }

    auto [size, free] = osl::GetTotalAndFree(names[0]);

    if (!size || !free) continue;

    auto [label, fs, serial] = osl::GetVolumeMetadata(names[0]);

    auto disks = osl::GetVolumeDiskExtents(names[0]);

    if (disks.size() > 1) continue;

    auto diskName = QString("PhysicalDrive") + QString::number(disks[0]);

    auto parentDisk = std::find_if(m_model.begin(), m_model.end(), 
          [diskName](const auto& e) -> bool {
            return std::static_pointer_cast<BlockDevice>(e)->m_names[0] == diskName;
          });

    if (parentDisk == std::end(m_model))
    {
      auto item = std::make_shared<BlockDevice>(QVector<QString>(diskName), 0, 1, true);
      item->m_disk = disks[0];
      item->isDisk = true;
      m_model.push_back(item);
    }
    else
    {
      (*parentDisk)->m_children++;
    }

    QVector<QString> qnames;
    for (auto& name : names)
    {
      qnames.prepend(QString::fromStdWString(name));
    }

    auto item = std::make_shared<BlockDevice>(qnames, 1, children.size(), true, size, free);

    item->m_fs = QString::fromStdWString(fs);
    item->m_label = QString::fromStdWString(label);
    item->m_serial = serial;
    item->m_disk = disks[0];

    m_model.push_back(item);

    for (const auto& child : children)
    {
      auto [size, free] = osl::GetTotalAndFree(child.toStdWString().c_str());
      auto c = std::make_shared<BlockDevice>(QVector<QString>(child), 2, 0, true, size, free);
      c->m_textColor = QColor(220, 220, 170);
      auto [label, fs, serial] = osl::GetVolumeMetadata(child.toStdWString());
      c->m_fs = QString::fromStdWString(fs);
      c->m_label = QString::fromStdWString(label);
      c->m_serial = serial;
      c->m_disk = disks[0];
      m_model.push_back(c);
    }
  }

  std::sort(m_model.begin(), m_model.end(),
    [](const auto& x, const auto& y) -> bool {
      return (std::static_pointer_cast<BlockDevice>(x))->m_disk <
                (std::static_pointer_cast<BlockDevice>(y))->m_disk;
    }
  );

  endResetModel();
}