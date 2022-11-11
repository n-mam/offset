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
  }
  int m_depth = 0;
  int m_children = 0;
  QVector<QString> m_names;
  bool m_selected = false;
  bool m_visible = true;
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
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

  Q_INVOKABLE int ToggleTreeAtIndex(int index, bool expanded, bool isRoot = true);

  std::vector<SPBaseItem> m_model;

  enum Roles
  {
    EDepth = Qt::UserRole,
    EVisible,
    ESelected,
    EHasChildren,
    ELastRole
  };

  public slots:

  virtual void RefreshModel() {};

  private:

  QString m_colors[3] = {"#EAEDED", "#00bfff", "#F9E79F"};
};

#endif // BASEMODEL_H
