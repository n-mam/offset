#include <vector>

#include <QJSEngine>

#include <BaseModel.h>

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
    return static_cast<int>(m_model.size());
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

QHash<int, QByteArray> BaseModel::roleNames() const
{
  auto roles = QAbstractItemModel::roleNames();
  roles.insert(EDepth, "depthRole"); 
  roles.insert(ESelectable, "selectableRole");
  roles.insert(EHasChildren, "hasChildrenRole");
  roles.insert(Qt::ForegroundRole, "textColorRole");
  return roles;
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
        return m_model[row]->m_names;
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

void BaseModel::updateItemSelection(QVariant data, bool selected)
{
  qDebug() << data << selected;

  m_selected.erase(
    std::remove_if(
      m_selected.begin(), m_selected.end(),
      [this, &data](const auto& e){
        auto e1 = ((qjsEngine(this))->toScriptValue(data)).property(0).toVariant();
        auto e2 = ((qjsEngine(this))->toScriptValue(e)).property(0).toVariant();
        return e1 == e2;
      }),
    m_selected.end()
  );

  if (selected)
  {
    m_selected.push_back(data);
  }
}

QVector<QVariant> BaseModel::getSelectedItems(void)
{
  return m_selected;
}