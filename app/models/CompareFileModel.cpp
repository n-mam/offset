#include <sstream>
#include <fstream>

#include <CompareManager.h>
#include <CompareFileModel.h>

#include <osl/log>
#include <osl/singleton>

CompareFileModel::CompareFileModel() {
    _model.reserve(2048);
    auto cm = getInstance<CompareManager>();
    cm->setCompareFileModel(this);
    connect(this, &CompareFileModel::documentChanged,
        cm, &CompareManager::onFileModelChanged);
}

CompareFileModel::~CompareFileModel()
{
}

QHash<int, QByteArray> CompareFileModel::roleNames() const {
    auto roles = QAbstractListModel::roleNames();
    roles.insert(ELineReal, "lineReal");
    roles.insert(ELineHash, "lineHash");
    roles.insert(ELineText, "lineText");
    roles.insert(ELineIndent, "lineIndent");
    roles.insert(ELineNumber, "lineNumber");
    roles.insert(ELineBgColor, "lineBgColor");
    roles.insert(ELineChildren, "lineChildren");
    roles.insert(ELineChildCount, "lineChildCount");
    roles.insert(ELineIndentSymbol, "lineIndentSymbol");
    return roles;
}

int CompareFileModel::rowCount(const QModelIndex &parent) const {
    return static_cast<int>(_model.size());
}

QVariant CompareFileModel::data(const QModelIndex &index, int role) const {

    if (!index.isValid()) 
        return QVariant();

    auto row = index.row();

    switch (role) {
        case ELineReal: {
            return _model[row].e_real;
        }
        case ELineIndent: {
            return _model[row].e_indent;
        }
        case ELineNumber: {
            return (qlonglong)(row + 1);
        }
        case ELineHash: {
            return (qlonglong)_model[row].e_hash;
        }
        case ELineText: {
            return QString::fromStdString(_model[row].e_text);
        }
        case ELineBgColor: {
            return QString::fromStdString(_model[row].e_bgcolor);
        }
        case ELineIndentSymbol: {
            return QString::fromStdString(_model[row].e_indentSymbol);
        }
        case ELineChildCount: {
            return (qlonglong)_model[row].e_child.size();
        }
        case ELineChildren: {
            QList<QVariantMap> children;
            for (const auto& e : _model[row].e_child) {
                QVariantMap data;
                data["real"] = e.e_real;
                data["text"] = QString::fromStdString(e.e_text);
                data["color"] = QString::fromStdString(e.e_bgcolor);
                children << data;
            }
            return QVariant::fromValue<QList<QVariantMap>>(children);
        }
    }

    return {};
}

QString CompareFileModel::getDocument() {
    return QString::fromStdString(m_document);
}

void CompareFileModel::setDocument(QString document) {
    if (document != QString::fromStdString(m_document)) {
        m_document = document.toStdString();
        beginResetModel();
        _model.clear();
        if (!load_as_xml(m_document)) {
            load_as_txt(m_document);
        }
        endResetModel();
        emit documentChanged(this);
    }
}

void CompareFileModel::insertStripedRows(int offset, int count) {
    beginInsertRows(QModelIndex(), offset, offset + count);
    _model.insert(_model.begin() + offset, count, {});
    endInsertRows();
    _changed = true;
}

void CompareFileModel::resetToOriginalState() {
        beginResetModel();
        //remove striped rows
        if (_changed) {
            _model.erase(
                std::remove_if(_model.begin(), _model.end(),
                    [](const auto& e){ return !e.e_real; }),
                _model.end());
        }
        //reset colors
        for (auto& e : _model) {
            e.e_bgcolor = "";
        }
        endResetModel();
}

bool CompareFileModel::load_as_txt(const std::string& file) {
    std::string line;
    std::ifstream f(file.c_str());
    beginResetModel();
    while (std::getline(f, line)) {
        _model.push_back({true, 0, std::hash<std::string>{}(line), line});
    }
    endResetModel();
    return true;
}

bool CompareFileModel::load_as_xml(const std::string& file) {

    tinyxml2::XMLDocument xmlDoc;

    auto result = xmlDoc.LoadFile(file.c_str());

    if (result != tinyxml2::XML_SUCCESS) { 
        ERR << "error : " << result;
        return false;
    }

    auto root = xmlDoc.RootElement();

    if (!root) { 
        ERR << "error : RootElement ";
        return false;
    }

    auto rootElement = root->FirstChildElement();

    std::string t(rootElement->Name());

    beginResetModel();

    _model.push_back({true, 0, std::hash<std::string>{}(t), t});

    traverse_element(rootElement, 1);

    endResetModel();

    return true;
}

void CompareFileModel::traverse_element(tinyxml2::XMLElement *element, int depth) {

    auto childElement = element->FirstChildElement();

    while (childElement) {

        std::string text;
        std::stringstream ss;
        std::string attribute_list;
        std::string name = std::string(childElement->Name());

        if (name == "w:t") {
            text = childElement->GetText() ? childElement->GetText() : "";
        }

        auto attribute = childElement->FirstAttribute();

        while (attribute) {
            ss << attribute->Name() << ":" << attribute->Value() << " ";
            attribute = attribute->Next();
        }

        attribute_list = ss.str();

        if (!attribute_list.empty()) {
            attribute_list.pop_back();
        }

        auto line = name 
            + (attribute_list.empty() ? "" : " " + attribute_list)
            + (text.empty() ? "" : " \"" + text + "\"");

        _model.push_back({true, depth + 2, std::hash<std::string>{}(line), line});

        traverse_element(childElement, depth + 2);

        childElement = childElement->NextSiblingElement();
    }
}