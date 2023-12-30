#include <sstream>

#include <osl/log>

#include <TextModel.h>

TextModel::TextModel()
{
}

TextModel::~TextModel()
{
}

QHash<int, QByteArray> TextModel::roleNames() const {
    auto roles = QAbstractListModel::roleNames();
    roles.insert(ELineIndent, "lineIndent");
    roles.insert(ELineHash, "lineHash");
    roles.insert(ELineText, "lineText");
    roles.insert(ELineNumber, "lineNumber");
    roles.insert(ELineIndentSymbol, "lineIndentSymbol");
    return roles;
}

int TextModel::rowCount(const QModelIndex &parent) const {
    return static_cast<int>(m_model.size());
}

QVariant TextModel::data(const QModelIndex &index, int role) const {

    if (!index.isValid()) return QVariant();

    auto row = index.row();

    switch (role) {
        case ELineIndent: {
            return m_model[row].li_indent;
        }
        case ELineHash: {
            return (qlonglong)m_model[row].li_hash;
        }
        case ELineText: {
            return QString::fromStdString(m_model[row].li_text);
        }
        case ELineIndentSymbol: {
            return QString::fromStdString(m_model[row].li_indentSymbol);
        }
        case ELineNumber: {
            return (qlonglong)m_model[row].li_number;
        }
    }

    return {};
}

QString TextModel::getDocument() {
    return QString::fromStdString(m_document);
}

void TextModel::setDocument(QString document) {
    if (document != QString::fromStdString(m_document)) {
        m_document = document.toStdString();
        load_xml_model(m_document);
        emit documentChanged(document);
    }
}

void TextModel::load_xml_model(const std::string& file) {

    tinyxml2::XMLDocument xmlDoc;

    auto result = xmlDoc.LoadFile(file.c_str());

    if (result != tinyxml2::XML_SUCCESS) { 
        ERR << "error : " << result;
        return;
    }

    auto root = xmlDoc.RootElement();

    if (!root) { 
        ERR << "error : RootElement ";
        return;
    }

    auto rootElement = root->FirstChildElement();

    std::string t(rootElement->Name());

    beginResetModel();

    m_model.push_back({0, m_model.size() + 1, std::hash<std::string>{}(t), t});

    traverse_element(rootElement, 1);

    endResetModel();
}


void TextModel::traverse_element(tinyxml2::XMLElement *element, int depth) {

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

        m_model.push_back({depth + 2, m_model.size() + 1, std::hash<std::string>{}(line), line});

        traverse_element(childElement, depth + 2);

        childElement = childElement->NextSiblingElement();
    }
}
