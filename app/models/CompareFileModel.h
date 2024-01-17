#ifndef COMPARE_FILE_H
#define COMPARE_FILE_H

#include <vector>
#include <string>

#include <zip.h>
#include <tinyxml2.h>

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
        ELineIndentSymbol
    };

    struct LineItem {
        bool li_real;
        int li_indent;
        std::size_t li_hash;
        std::string li_text;
        std::string li_bgcolor;
        std::string li_indentSymbol = "&nbsp;";
    };

    public:

    CompareFileModel();
    ~CompareFileModel();

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    Q_PROPERTY(QString document READ getDocument WRITE setDocument NOTIFY documentChanged);

    void resetToOriginalState();
    void insertStripedRows(int offset, int count);

    QString getDocument();
    void setDocument(QString document);

    signals:

    void documentChanged(CompareFileModel *model);

    private:

    bool load_as_xml(const std::string& file);
    bool load_as_txt(const std::string& file);
    void traverse_element(tinyxml2::XMLElement *element, int depth);

    bool _changed = false;
    std::string m_document;
    std::vector<LineItem> _model;
};

#endif