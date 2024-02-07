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
        ElementHash = Qt::UserRole,
        ElementReal,
        ElementText,
        ElementNumber,
        ElementIndent,
        ElementDiffFull,
        ElementDiffPart,
        ElementChildren,
        ElementDiffAdded,
        ElementChildCount,
    };

    struct Element {
        std::size_t e_hash;
        std::string e_text;
        struct {
            uint32_t _real: 1;
            uint32_t _indent: 7;
            uint32_t _diff_full: 1; // red
            uint32_t _diff_added: 1; // green
            uint32_t _diff_part: 1; // light red
        } e_flags;
        std::vector<Element> e_child;
        auto _real() const {
            return (bool)(e_flags._real);
        }
        auto _indent() const {
            return (int)(e_flags._indent);
        }
        auto _set_added() {
            e_flags._diff_added = 1;
        }
        auto _set_full() {
            e_flags._diff_full = 1;
        }
        auto _set_part() {
            e_flags._diff_part = 1;
        }
        auto _added() const {
            return (bool)(e_flags._diff_added);
        }
        auto _full() const {
            return (bool)(e_flags._diff_full);
        }
        auto _part() const {
            return (bool)(e_flags._diff_part);
        }
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

    void documentChanged(CompareFileModel *model);

    private:

    bool load_as_xml(const std::string& file);
    bool load_as_txt(const std::string& file);
    void traverse_element(tinyxml2::XMLElement *element, uint32_t indent);

    std::string m_document;

    std::vector<Element> _model;
};

#endif