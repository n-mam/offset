#include <sstream>
#include <fstream>

#include <CompareManager.h>
#include <CompareFileModel.h>

#include <osl/log>
#include <osl/str>
#include <osl/singleton>

CompareFileModel::CompareFileModel() {
    _model.reserve(2048);
    auto cm = getInstance<CompareManager>();
    cm->setCompareFileModel(this);
    connect(this, &CompareFileModel::documentChanged,
        cm, &CompareManager::onFileModelChanged);
}

CompareFileModel::~CompareFileModel() {}

QHash<int, QByteArray> CompareFileModel::roleNames() const {
    auto roles = QAbstractListModel::roleNames();
    roles.insert(ElementReal, "elementReal");
    roles.insert(ElementHash, "elementHash");
    roles.insert(ElementText, "elementText");
    roles.insert(ElementIndent, "elementIndent");
    roles.insert(ElementNumber, "elementNumber");
    roles.insert(ElementDiffFull, "elementDiffFull");
    roles.insert(ElementDiffPart, "elementDiffPart");
    roles.insert(ElementChildren, "elementChildren");
    roles.insert(ElementDiffAdded, "elementDiffAdded");
    roles.insert(ElementChildCount, "elementChildCount");
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
        case ElementReal: {
            return _model[row]._real();
        }
        case ElementIndent: {
            return _model[row]._indent();
        }
        case ElementNumber: {
            return (qlonglong)(row + 1);
        }
        case ElementDiffAdded: {
            return _model[row]._added();
        }
        case ElementDiffFull: {
            return _model[row]._full();
        }
        case ElementDiffPart: {
            return _model[row]._part();
        }
        case ElementHash: {
            return (qlonglong)_model[row].e_hash;
        }
        case ElementText: {
            return QString::fromStdString(_model[row].e_text);
        }
        case ElementChildCount: {
            return (qlonglong)_model[row].e_child.size();
        }
        case ElementChildren: {
            QList<QVariantMap> children;
            for (const auto& e : _model[row].e_child) {
                QVariantMap data;
                data["real"] = e._real();
                data["full"] = e._full();
                data["added"] = e._added();
                data["text"] = QString::fromStdString(e.e_text);
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

bool CompareFileModel::load_as_txt(const std::string& file) {
    char ch;
    std::string line;
    beginResetModel();
    std::ifstream fs(file.c_str(), std::ios::binary);
    do {
        ch = fs.get();
        line += ch;
        if (ch == '\r' || ch == '\n') {
            ch = fs.get();
            line += ch;
            if (ch == '\r' || ch == '\n') {
                _model.push_back({osl::hash(line), line, {1, 0}});
                line.clear();
            }
        }
    } while(std::char_traits<char>::not_eof(ch));
    fs.close();
    if (line.size()) {
        _model.push_back({osl::hash(line), line, {1, 0}});
    }
    // while (std::getline(f, line)) {
    //     _model.push_back({
    //         std::hash<std::string>{}(line),
    //         line,
    //         {1, 0}
    //     });
    // }
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
    _model.push_back({osl::hash(t), t, {1, 0}});
    traverse_element(rootElement, 1);
    endResetModel();
    return true;
}

void CompareFileModel::traverse_element(tinyxml2::XMLElement *element, uint32_t indent) {
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
        _model.push_back({osl::hash(line), line, {1, indent + 2}});
        traverse_element(childElement, indent + 2);
        childElement = childElement->NextSiblingElement();
    }
}