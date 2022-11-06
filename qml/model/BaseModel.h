#ifndef BASEMODEL_H
#define BASEMODEL_H

#include <memory>

#include <QColor>
#include <QModelIndex>
#include <QAbstractItemModel>

struct BaseItem
{
  BaseItem(
    QVector<QString> names, 
    int depth = 0, 
    int children = 0, 
    int selectable = false)
  {
    m_names = names;
    m_depth = depth;
    m_children = children;
    m_selectable = selectable;
  }
  QVector<QString> m_names;
  int m_depth = 0;
  int m_children = 0;
  bool m_selectable = false;
  QColor m_textColor = QColor("#00bfff");
};

using SPBaseItem = std::shared_ptr<BaseItem>;

class BaseModel : public QAbstractItemModel
{
  Q_OBJECT

  public:

  BaseModel();
  ~BaseModel();

  QHash<int, QByteArray> roleNames() const override;
  QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
  QModelIndex parent(const QModelIndex& index) const override;
  int rowCount(const QModelIndex& index = QModelIndex()) const override;
  int columnCount(const QModelIndex& index = QModelIndex()) const override;
  QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

  Q_INVOKABLE void updateItemSelection(QVariant data, bool selected);
  Q_INVOKABLE QVector<QVariant> getSelectedItems(void);

  std::vector<SPBaseItem> m_model;
  QVector<QVariant> m_selected;

  enum Roles
  {
    EDepth = Qt::UserRole,
    ESelectable,
    EHasChildren,
    ELastRole
  };

};

#endif // BASEMODEL_H
