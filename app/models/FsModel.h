#ifndef FSMODEL
#define FSMODEL

#include <QAbstractListModel>

#include <TransferManager.h>

struct FileElement {
    std::string m_name;
    std::string m_size;
    std::string m_timestamp;
    std::string m_attributes;
    bool m_selected = false;
};

class FsModel : public QAbstractListModel {

    Q_OBJECT

    enum Roles {
        EFileName = Qt::UserRole,
        EFileSize,
        EFileIsDir,
        EFileAttributes,
        EFileIsSelected,
    };

    public:

    FsModel();
    ~FsModel();

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;

    Q_PROPERTY(QString pathSeperator READ getPathSeperator);
    Q_PROPERTY(QString totalFilesAndFolders READ getTotalFilesAndFolder);
    Q_PROPERTY(QString currentDirectory READ getCurrentDirectory WRITE setCurrentDirectory);

    Q_INVOKABLE virtual void UnselectAll();
    Q_INVOKABLE virtual void RemoveSelectedItems();
    Q_INVOKABLE virtual void RemoveFile(QString path) = 0;
    Q_INVOKABLE virtual void SelectRange(int start, int end);
    Q_INVOKABLE virtual QVariant get(int index, QString role);
    Q_INVOKABLE virtual void RemoveDirectory(QString path) = 0;
    Q_INVOKABLE virtual void CreateDirectory(QString path) = 0;
    Q_INVOKABLE virtual void SelectIndex(int index, bool select);
    Q_INVOKABLE virtual void Rename(QString from, QString to) = 0;
    Q_INVOKABLE virtual void QueueTransfers(bool start = false) = 0;

    signals:

    void directoryList(void);

    public slots:

    virtual QString getPathSeperator(void);
    virtual QString getTotalFilesAndFolder(void);
    virtual QString getCurrentDirectory(void);
    virtual void setCurrentDirectory(QString);
    virtual QString getParentDirectory(void);

    protected:

    bool IsElementDirectory(int index) const;
    uint64_t GetElementSize(int index) const;

    int m_fileCount = 0;
    int m_folderCount = 0;
    std::string m_currentDirectory;
    std::vector<FileElement> m_model;
    #if defined _WIN32
    char path_sep = '\\';
    #else
    char path_sep = '/';
    #endif
};

#endif