#include <BaseModel.h>

#include <vector>

BaseModel::BaseModel()
{
}

BaseModel::~BaseModel()
{
}

QModelIndex BaseModel::index(int row, int column, const QModelIndex& parent) const
{
  if (!parent.isValid())
    return QAbstractItemModel::createIndex(row, column, 999);
  else
    return QAbstractItemModel::createIndex(row, column, parent.row());
}

QModelIndex BaseModel::parent(const QModelIndex& index) const
{
  auto iid = index.internalId();

  if (iid == 999)
    return QModelIndex();
  else
    return createIndex(iid, 0, 999);
}

int BaseModel::rowCount(const QModelIndex& index) const
{
  if (!index.isValid())
  {
    return m_model.size();
  }

  return 0;
}

int BaseModel::columnCount(const QModelIndex& index) const
{
  auto row = index.row();
  auto column = index.column();

  if (!index.isValid())
  {
    return 1;
  }
  else if (column == 0 && index.isValid() && !index.parent().isValid())
  {
    return 1;
  }

  return 0;
}

QVariant BaseModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  auto row = index.row();
  auto column = index.column();

  switch (role)
  {
    case Qt::DisplayRole:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return m_model[row]->m_name;
      }
      break;
    }
    
    case Qt::ForegroundRole:
    {
      return QColor(m_model[row]->m_textColor);
    }

    case EHasChildren:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return m_model[row]->m_children;
      }
      break;
    }

    case EDepth:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return m_model[row]->m_depth;
      }
      break;
    }

    case ESelectable:
    {
      if (column == 0 && !index.parent().isValid())
      {
        return m_model[row]->m_selectable;
      }
      break;
    }

    default:
      return {};
  }

  return QVariant();
}

void BaseModel::updateItemSelection(QString name, bool selected)
{
  qDebug() << name << selected;
  if (selected)
  {
    m_selected.push_back(name);
  }
  else
  {
    m_selected.erase(
      std::remove(m_selected.begin(), m_selected.end(), name),
      m_selected.end()
    );
  }
}

QVector<QString> BaseModel::getSelectedItems(void)
{
  return m_selected;
}