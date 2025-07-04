#ifndef LOCALFSMODEL
#define LOCALFSMODEL

#include <FsModel.h>

#include <QAbstractListModel>

class LocalFsModel : public FsModel {

    Q_OBJECT

    public:

    LocalFsModel();
    ~LocalFsModel();

    Q_INVOKABLE virtual void RemoveFile(QString path) override;
    Q_INVOKABLE virtual void RemoveDirectory(QString path) override;
    Q_INVOKABLE virtual void CreateDirectory(QString path) override;
    Q_INVOKABLE virtual void Rename(QString from, QString to) override;
    Q_INVOKABLE virtual void QueueTransfers(bool start = false) override;

    public slots:

    virtual void setCurrentDirectory(QString) override;

    protected:

    void UploadInternal(const std::string& file, const std::string& folder, const std::string& localFolder, bool isFolder, uint64_t size = 0);
};

#endif