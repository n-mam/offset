#ifndef DISKLISTMODEL_HPP
#define DISKLISTMODEL_HPP

#include <memory>
#include <future>

#include <BaseModel.h>

struct BlockDevice : public BaseItem {
    BlockDevice(
      QVector<QString> names,
      int depth = 0,
      int children = 0,
      uint64_t size = 0,
      uint64_t free = 0) : BaseItem(names, depth, children)
    {
      m_size = (double)size / (1ULL*1024*1024*1024);
      m_free = (double)free / (1ULL*1024*1024*1024);
    }

    QString m_fs;
    int m_disk = -1;
    QString m_label;
    double m_size = 0;
    double m_free = 0;
    bool m_isDisk = false;
    QString m_diskPartition;
    uint64_t m_diskLength = 0;
    QString m_serial;
    int m_sourceIndex;
    int m_formatIndex;
    QVector<QString> m_sourceOptions;
    QVector<QString> m_formatOptions;
    QList<QVariant> m_excludeList;
};

using SPBlockDevice = std::shared_ptr<BlockDevice>;

class DiskListModel : public BaseModel {
    Q_OBJECT
    public:
    DiskListModel();
    ~DiskListModel();
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    Q_INVOKABLE bool convertSelectedItemsToVirtualDisks(QString folder);

    Q_PROPERTY(bool stop READ getStop WRITE setStop);
    Q_PROPERTY(int transfer READ getTransfer WRITE setTransfer NOTIFY transferChanged);

    enum Roles {
      ESize = BaseModel::ELastRole + 1,
      EFree,
      EIsDisk,
      EMetaData,
      EExcludeList,
      ESourceIndex,
      EFormatIndex,
      ESourceOptions,
      EFormatOptions
    };

    public slots:

    int getTransfer() const;
    void setTransfer(int);
    bool getStop() const;
    void setStop(bool);
    void refreshModel() override;

    private:

    int transfer = 0;
    bool stop = false;
    std::vector<std::future<void>> m_futures;

    signals:

    void transferChanged(int);
    void progress(QString, int);
};

#endif