#ifndef BASEMODEL_H
#define BASEMODEL_H

#include <memory>

#include <QColor>
#include <QModelIndex>
#include <QAbstractItemModel>

struct BaseItem {
    BaseItem(
        QVector<QString> names,
        int depth = 0,
        int children = 0,
        int selectable = false) {
        m_names = names;
        m_depth = depth;
        m_children = children;
    }
    int m_depth = 0;
    int m_children = 0;
    bool m_visible = true;
    bool m_enabled = true;
    bool m_selected = false;
    bool m_expanded = true;
    QVector<QString> m_names;
};

using SPBaseItem = std::shared_ptr<BaseItem>;

class BaseModel : public QAbstractItemModel {
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

    Q_INVOKABLE int ToogleChildSelectionAtindex(int row, bool selected, bool isRoot = true);
    Q_INVOKABLE int ToggleTreeExpandedAtIndex(int index, bool expanded, bool isRoot = true);

    std::vector<SPBaseItem> m_model;

    enum Roles {
        EDepth = Qt::UserRole,
        EVisible,
        EEnabled,
        ESelected,
        EExpanded,
        EHasChildren,
        ELastRole
    };

    public slots:
    virtual void refreshModel() {};

    private:
    QString m_colors[3] = {"#EB9CCD", "#FFFFFF", "#FFFFFF"};
};

#endif // BASEMODEL_H
