#ifndef COMPARE_FILE_H
#define COMPARE_FILE_H

#include <vector>
#include <string>

#include <zip.h>
#include <tinyxml2.h>

class CompareManager;

#include <QAbstractListModel>

struct CompareFileModel : public QAbstractListModel {

    friend class CompareManager;

    Q_OBJECT

    enum Roles {
        ELineHash = Qt::UserRole,
        ELineReal,
        ELineText,
        ELineNumber,
        ELineIndent,
        ELineBgColor,
        ELineTxColor,
        ELineIndentSymbol
    };

    struct LineItem {
        bool li_real;
        int li_indent;
        std::size_t li_hash;
        std::string li_text;
        std::string li_bgcolor;
        std::string li_txcolor;
        std::string li_indentSymbol = "&nbsp;";
    };

    public:

    CompareFileModel();
    ~CompareFileModel();

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    Q_PROPERTY(QString document READ getDocument WRITE setDocument NOTIFY documentChanged);

    QString getDocument();
    void setDocument(QString document);

    signals:

    void documentChanged(QString);

    private:

    bool load_as_xml(const std::string& file);
    bool load_as_txt(const std::string& file);
    void traverse_element(tinyxml2::XMLElement *element, int depth);

    std::string m_document;
    std::vector<LineItem> m_model;
};

#endif