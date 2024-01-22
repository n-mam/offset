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

    struct Element {
        bool e_real;
        int e_indent;
        std::size_t e_hash;
        std::string e_text;
        std::string e_bgcolor;
        std::string e_indentSymbol = "&nbsp;";
        std::vector<Element> e_child;
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

    std::vector<Element> _model;
};

#endif