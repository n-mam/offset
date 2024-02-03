#include <vector>

#include <osl/log>
#include <BaseModel.h>

BaseModel::BaseModel(){}

BaseModel::~BaseModel(){}

QHash<int, QByteArray> BaseModel::roleNames() const {
    auto roles = QAbstractItemModel::roleNames();
    roles.insert(EDepth, "depth");
    roles.insert(EVisible, "visible");
    roles.insert(EEnabled, "enabled");
    roles.insert(ESelected, "selected");
    roles.insert(EExpanded, "expanded");
    roles.insert(EHasChildren, "hasChildren");
    roles.insert(Qt::ForegroundRole, "textColor");
    return roles;
}

QModelIndex BaseModel::index(int row, int column, const QModelIndex& parent) const {
    if (!parent.isValid())
        return QAbstractItemModel::createIndex(row, column, 999);
    else
        return QAbstractItemModel::createIndex(row, column, parent.row());
}

QModelIndex BaseModel::parent(const QModelIndex& index) const {
    auto iid = index.internalId();
    if (iid == 999)
        return QModelIndex();
    else
        return createIndex(iid, 0, 999);
}

int BaseModel::rowCount(const QModelIndex& index) const {
    if (!index.isValid()) {
        return static_cast<int>(m_model.size());
    }
    return 0;
}

int BaseModel::columnCount(const QModelIndex& index) const {
    auto row = index.row();
    auto column = index.column();
    if (!index.isValid()) {
        return 1;
    } else if (column == 0 && index.isValid() && !index.parent().isValid()) {
        return 1;
    }
    return 0;
}

QVariant BaseModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid()) return {};
    auto row = index.row();
    auto column = index.column();
    switch (role) {
        case Qt::DisplayRole: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_names;
            }
            break;
        }
        case Qt::ForegroundRole: {
            return QColor(m_colors[m_model[row]->m_depth]);
        }
        case EHasChildren: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_children;
            }
            break;
        }
        case EDepth: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_depth;
            }
            break;
        }
        case EVisible: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_visible;
            }
            break;
        }
        case EExpanded: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_expanded;
            }
            break;
        }
        case EEnabled: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_enabled;
            }
            break;
        }
        case ESelected: {
            if (column == 0 && !index.parent().isValid()) {
                return m_model[row]->m_selected;
            }
            break;
        }
        default:
        return {};
    }
    return QVariant();
}

bool BaseModel::setData(const QModelIndex &index, const QVariant &value, int role) {
    bool fRet = true;
    switch (role) {
        case ESelected:
            m_model[index.row()]->m_selected = value.toBool();
            break;
        case EVisible:
            m_model[index.row()]->m_visible = value.toBool();
            break;
        case EExpanded:
            m_model[index.row()]->m_expanded = value.toBool();
            break;
        default:
            fRet = false;
            break;
    }
    if (fRet) {
        emit dataChanged(index, index, {role});
    }
    return fRet;
}

int BaseModel::ToogleChildSelectionAtindex(int row, bool selected, bool isRoot) {
    int totalChildren = 0;
    if (m_model[row]->m_children) {
        for (int i = 1; i <= m_model[row]->m_children; i++)
        totalChildren += ToogleChildSelectionAtindex(row + i + totalChildren, selected, false);
    }
    if (isRoot) {
        emit dataChanged(
        createIndex(row, 0, 999),
        createIndex(row + m_model[row]->m_children + totalChildren, 0, 999));
    } else {
        m_model[row]->m_selected = selected;
    }
    return m_model[row]->m_children;
}

int BaseModel::ToggleTreeExpandedAtIndex(int row, bool isExpanded, bool isRoot) {
    int totalChildren = 0;
    if (m_model[row]->m_children) {
        for (int i = 1; i <= m_model[row]->m_children; i++) {
            totalChildren += ToggleTreeExpandedAtIndex(row + i + totalChildren, isExpanded, false);
        }
    }
    if (isRoot) {
        emit dataChanged(
        createIndex(row, 0, 999),
        createIndex(row + m_model[row]->m_children + totalChildren, 0, 999));
    } else {
        m_model[row]->m_visible = isExpanded;
    }
    m_model[row]->m_expanded = isExpanded;
    return m_model[row]->m_children;
}