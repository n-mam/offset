#ifndef VTKQUICKITEM_H
#define VTKQUICKITEM_H

#include <mutex>
#include <atomic>

#include <vtkObject.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>

#include <imu.h>
#include "QQuickVTKItem.h"
#include <SerialPortManager.h>
#include <point.cloud.pipeline.h>

#include <QUrl>
#include <QThread>
#include <QFileInfo>

struct VtkContext : vtkObject {
    static VtkContext* New();
    sppl active_pipeline;
    std::vector<sppl> pipelines;
    vtkTypeMacro(VtkContext, vtkObject);
    vtkSmartPointer<vtkRenderer> renderer;
    vtkSmartPointer<vtkRenderWindow> renderWindow;
    vtkSmartPointer<vtkRenderWindowInteractor> interactor;
};

struct VtkQuickItem : public QQuickVTKItem {

    Q_OBJECT
    QML_ELEMENT

    public:
    ~VtkQuickItem();

    std::mutex mux;
    std::thread _thread;
    std::atomic<bool> stop{false};
    QQuickVTKItem::vtkUserData _ctx;
    std::atomic<bool> cloud_loaded{false};
    std::atomic<bool> camera_initialized{false};

    imu::orientation _orientation;
    QThread* _serialThread = nullptr;
    SerialPortManager *_serial = nullptr;

    Q_INVOKABLE void fit_to_cloud();
    Q_INVOKABLE void stop_load();    
    Q_INVOKABLE void elevation_filter_pmf();
    Q_INVOKABLE void restore_base_pipeline();
    Q_INVOKABLE void stop_imu_visualization();
    Q_INVOKABLE void apply_scalar(QString name);
    Q_INVOKABLE void elevation_filter_ransac();    
    Q_INVOKABLE void load_point_cloud(QUrl filePath);
    Q_INVOKABLE void start_imu_visualization(QString);

    bool has_cloud();
    void clear_scene();
    sppl base_pipeline();
    VtkContext *context();
    sppl active_pipeline();
    void syncToVTK(sppl pipeline);
    sppl get_pipeline(vis::filter f);
    void set_active_pipeline(sppl pipeline);
    void applyQuaternion(const imu::quaternion& q);
    void onReadSerialLine(const QByteArray& line);

    void compute_color_map(const std::string& arrayName);
    vtkSmartPointer<VtkContext> create_scene(vtkRenderWindow*);
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
    sppl build_filtered_pipeline(
        sppl source,
        const std::vector<int>& indices,
        vis::filter filter_type);
    void activate_pipeline_async(sppl pipeline);

    signals:
    void distanceUpdated(int);
    void pointCloudUpdated(int, uint64_t, uint64_t);
};

#endif // VTKQUICKITEM_H