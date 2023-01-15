#include <fxc/fxc>

#include <DiskListModel.h>

DiskListModel::DiskListModel()
{
  refreshModel();
  npl::make_dispatcher();
  fxc::startExcludeListWriterThread();
}

DiskListModel::~DiskListModel()
{
  fxc::stopExcludeListWriterThread();
}

QHash<int, QByteArray> DiskListModel::roleNames() const
{
  QHash<int, QByteArray> roles = BaseModel::roleNames();

  roles.insert(ESize, "sizeRole");
  roles.insert(EFree, "freeRole");
  roles.insert(EIsDisk, "isDisk");
  roles.insert(ESourceIndex, "sourceIndex");
  roles.insert(EExcludeList, "excludeList");
  roles.insert(ESourceOptions, "sourceOptions");
  roles.insert(EFormatOptions, "formatOptions");
  roles.insert(EFormatIndex, "formatIndex");
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

        if (bd->m_isDisk)
        {
          return QVector<QString>({bd->m_diskPartition, QString::number(bd->m_diskLength) + "g"});
        }
        else
        {
          return QVector<QString>({bd->m_fs, bd->m_label, bd->m_serial.toUpper()});
        }
        
      }
      break;
    }

    case EIsDisk:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_isDisk;
      }
      break;
    }

    case EFormatOptions:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_formatOptions;
      }
      break;
    }

    case EFormatIndex:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_formatIndex;
      }
      break;
    }

    case ESourceOptions:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_sourceOptions;
      }
      break;
    }

    case ESourceIndex:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_sourceIndex;
      }
      break;
    }

    case EExcludeList:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return std::static_pointer_cast<BlockDevice>(m_model[row])->m_excludeList;
      }
      break;
    }

    default:
      return BaseModel::data(index, role);
  }

  return QVariant();
}

bool DiskListModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  auto fRet = BaseModel::setData(index, value, role);

  if (!fRet)
  {
    fRet = true;
    
    auto bd = std::static_pointer_cast<BlockDevice>(m_model[index.row()]);

    switch (role)
    {
      case EFormatIndex:
        bd->m_formatIndex = value.toInt();
      break;

      case ESourceIndex:
        bd->m_sourceIndex = value.toInt();
      break;

      case EExcludeList:
      {
        auto list = value.toList();

        if (list.isEmpty())
        {
          bd->m_excludeList.clear();
        }
        else
        {
          bd->m_excludeList += list;
        }
      }
      break;

      default:
        fRet = false;
        break;
    }

    if (fRet)
    {
      emit dataChanged(index, index, {role});
    }
  }

  return fRet;
}

int DiskListModel::getTransfer() const
{
  return transfer;
}

void DiskListModel::setTransfer(int current)
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

bool DiskListModel::convertSelectedItemsToVirtualDisks(QString destination)
{
  std::vector<fxc::TBackupConfig> configuration;

  if (destination.isEmpty())
  {
    STATUS << "Backup destination not specified";
    return false;
  }

  for (auto& item : m_model)
  {
    if (!item->m_selected) continue;

    auto blockdevice = std::static_pointer_cast<BlockDevice>(item);

    auto names = blockdevice->m_names;
    auto format = blockdevice->m_formatOptions[blockdevice->m_formatIndex];
    auto live = blockdevice->m_sourceOptions[blockdevice->m_sourceIndex] == "live";

    std::vector<std::wstring> exclude;

    foreach(const auto& item, blockdevice->m_excludeList)
    {
      exclude.push_back(item.toString().toStdWString());
    }

    QString name = names.size() == 1 ? names[0] : names[1];

    LOG << name.toStdWString() << L", " << format.toStdWString() << L", " << live;

    configuration.push_back({
      name.toStdWString(),
      L"0",
      format.toStdWString(),
      destination.toStdWString(),
      exclude,
      live
    });
  }

  if (!configuration.size())
  {
    STATUS << "Please select the volumes to backup";
    return false;
  }

  setTransfer(static_cast<int>(configuration.size()));

  STATUS << "Transfer in progress : " << this->getTransfer();

  m_futures.push_back(std::async(std::launch::async, 
    [this, configuration](){
      fxc::ConvertBlockDeviceToVirtualImages(configuration, 
        [this](auto device, auto percent){
          QMetaObject::invokeMethod(this, [this, device, percent](){
            emit this->progress(QString::fromStdWString(device), percent);
            if (percent >= 100) {
              this->setTransfer(this->getTransfer() - 1);
              STATUS << "Transfer in progress : " << this->getTransfer();
            }
          }, Qt::QueuedConnection);
          return this->stop;
        });
      QMetaObject::invokeMethod(this, [this](){
        this->setTransfer(0);
        this->setStop(false);
        STATUS << "Transfer finished";
      });
    }
  ));

  return true;
}

void DiskListModel::refreshModel()
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

    auto [label, fs, serial] = osl::GetVolumeMetadata(names[0]);

    auto isSnapshotable = fxc::IsVolumeSupported(names[0]);

    auto disks = osl::GetVolumeDiskExtents(names[0]);

    //this(also) fails for dvd but is successful for RAW volumes
    if (!disks.size() || disks.size() > 1) continue;

    auto diskName = QString("PhysicalDrive") + QString::number(disks[0]);

    int depth = 0;

    auto parentDisk = std::find_if(m_model.begin(), m_model.end(), 
          [diskName](const auto& e) -> bool {
            return std::static_pointer_cast<BlockDevice>(e)->m_names[0] == diskName;
          });

    if (parentDisk == std::end(m_model))
    {
      auto item = std::make_shared<BlockDevice>(QVector<QString>(diskName), depth++, 1);
      item->m_disk = disks[0];
      item->m_isDisk = true;
      item->m_enabled = false;
      auto pi = osl::GetPartitionInformation(
         std::wstring(L"\\\\.\\PhysicalDrive") + std::to_wstring(disks[0]));
      if (pi.PartitionStyle == PARTITION_STYLE_MBR)
        item->m_diskPartition = "MBR";
      else if (pi.PartitionStyle == PARTITION_STYLE_GPT)
        item->m_diskPartition = "GPT";
      else if (pi.PartitionStyle == PARTITION_STYLE_RAW)
        item->m_diskPartition = "RAW";
      item->m_diskLength = pi.PartitionLength.QuadPart/(1024ull*1024*1024);
      item->m_sourceOptions << "vss" << "live"; //todo
      item->m_formatOptions << "d-vhd" << "f-vhd" << "d-vhdx"; //todo
      item->m_sourceIndex = item->m_formatIndex = 0; //todo
      m_model.push_back(item);
    }
    else
    {
      depth++;
      (*parentDisk)->m_children++;
    }


    QVector<QString> qnames;
    for (auto& name : names)
    {
      qnames.prepend(QString::fromStdWString(name));
    }

    auto item = std::make_shared<BlockDevice>(qnames, depth++, children.size(), size, free);

    item->m_sourceOptions << "live";

    if (isSnapshotable) 
    {
      item->m_sourceOptions << "vss";
      item->m_sourceIndex = item->m_sourceOptions.indexOf("vss");
    }
    else
    {
      item->m_sourceIndex = item->m_sourceOptions.indexOf("live");
    }

    item->m_formatOptions << "raw" << "d-vhdx";

    if (size < _2T)
    {
      item->m_formatOptions << "d-vhd" << "f-vhd";
      item->m_formatIndex = item->m_formatOptions.indexOf("d-vhd");
    }
    else
    {
      item->m_formatIndex = item->m_formatOptions.indexOf("d-vhdx");
    }

    item->m_fs = QString::fromStdWString(fs);
    item->m_label = QString::fromStdWString(label);
    item->m_serial.setNum(serial, 16);
    item->m_disk = disks[0];

    m_model.push_back(item);

    for (const auto& child : children)
    {
      auto [size, free] = osl::GetTotalAndFree(child.toStdWString().c_str());
      auto c = std::make_shared<BlockDevice>(QVector<QString>(child), depth, 0, size, free);

      c->m_sourceOptions << "live";
      c->m_sourceIndex = c->m_sourceOptions.indexOf("live");

      c->m_formatOptions << "raw" << "d-vhdx";

      if (size < _2T)
      {
        c->m_formatOptions << "d-vhd" << "f-vhd";
        c->m_formatIndex = c->m_formatOptions.indexOf("d-vhd");
      }
      else
      {
        c->m_formatIndex = c->m_formatOptions.indexOf("d-vhdx");
      }

      auto [label, fs, serial] = osl::GetVolumeMetadata(child.toStdWString());
      c->m_fs = QString::fromStdWString(fs);
      c->m_label = QString::fromStdWString(label);
      c->m_serial.setNum(serial, 16);
      c->m_disk = disks[0];
      m_model.push_back(c);
    }

    depth++;
  }

  std::sort(m_model.begin(), m_model.end(),
    [](const auto& x, const auto& y) -> bool {
      return (std::static_pointer_cast<BlockDevice>(x))->m_disk <
                (std::static_pointer_cast<BlockDevice>(y))->m_disk;
    });

  endResetModel();
}