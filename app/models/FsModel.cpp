#include <FsModel.h>

FsModel::FsModel()
{
}

FsModel::~FsModel()
{
}

QHash<int, QByteArray> FsModel::roleNames() const
{
  auto roles = QAbstractListModel::roleNames();

  roles.insert(EFileName, "fileName");
  roles.insert(EFileSize, "fileSize");
  roles.insert(EFileIsDir, "fileIsDir");
  roles.insert(EFileIsSelected, "fileIsSelected");
  roles.insert(EFileAttributes, "fileAttributes");

  return roles;
}

int FsModel::rowCount(const QModelIndex &parent) const
{
  return static_cast<int>(m_model.size());
}

QVariant FsModel::get(int row, QString role)
{
  if (role == "fileName") {
   return data(index(row, 0), EFileName);
  } else if (role == "fileSize") {
   return data(index(row, 0), EFileSize);
  } else if (role == "fileIsDir") {
   return data(index(row, 0), EFileIsDir);
  }
  return QVariant();
}

QVariant FsModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) return QVariant();

  auto row = index.row();

  switch (role)
  {
    case EFileName:
    {
      return QString::fromStdString(m_model[row].m_name);
    }

    case EFileIsDir:
    {
      return IsElementDirectory(row);
    }

    case EFileSize:
    {
      return QString::fromStdString(m_model[row].m_size);
    }

    case EFileIsSelected:
    {
      return m_model[row].m_selected;
    }

    case EFileAttributes:
    {
      return QString::fromStdString(m_model[row].m_attributes);
    }

    default: return {};
  }

  return QVariant();
}

bool FsModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  switch (role)
  {
    case EFileIsSelected:
    {
      m_model[index.row()].m_selected = value.toBool();
      emit dataChanged(index, index, {Roles::EFileIsSelected});
      break;
    }
    default:
      break;
  }
  return true;
}

bool FsModel::IsElementDirectory(int index) const
{
  return m_model[index].m_attributes[0] == 'd';
}

uint64_t FsModel::GetElementSize(int index) const
{
  return IsElementDirectory(index) ? 0 :
    std::stoll(m_model[index].m_size);
}

QString FsModel::getCurrentDirectory(void)
{
  return QString::fromStdString(m_currentDirectory);
}

void FsModel::setCurrentDirectory(QString directory)
{
  m_currentDirectory = directory.toStdString();
}

QString FsModel::getPathSeperator(void)
{
  return QString(path_sep);
}

QString FsModel::getTotalFilesAndFolder(void)
{
  return QString::number(m_fileCount) + ":" + QString::number(m_folderCount);
}

QString FsModel::getParentDirectory(void)
{
  return QString::fromStdString(
    std::filesystem::path(m_currentDirectory).parent_path().string()
  );
}