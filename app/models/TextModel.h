#ifndef TEXTMODEL_H
#define TEXTMODEL_H

#include <vector>
#include <string>

#include <zip.h>
#include <tinyxml2.h>

#include <QAbstractListModel>

struct TextModel : public QAbstractListModel {

    Q_OBJECT

    enum Roles {
        ELineHash = Qt::UserRole,
        ELineText,
        ELineNumber,
        ELineIndent,
        ELineIndentSymbol
    };

    struct LineItem {
        int li_indent;
        std::size_t li_number;
        std::size_t li_hash;
        std::string li_text;
        std::string li_indentSymbol = "&nbsp;";
    };

    public:

    TextModel();
    ~TextModel();

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    Q_PROPERTY(QString document READ getDocument WRITE setDocument NOTIFY documentChanged);

    QString getDocument();
    void setDocument(QString document);

    signals:

    void documentChanged(QString);

    private:

    void load_xml_model(const std::string& file);
    void traverse_element(tinyxml2::XMLElement *element, int depth);

    std::string m_document;
    std::vector<LineItem> m_model;
};

#endif