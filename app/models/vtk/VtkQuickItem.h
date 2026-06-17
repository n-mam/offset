#ifndef VTKQUICKITEM_H
#define VTKQUICKITEM_H

#include <mutex>
#include <atomic>

#include <vtkObject.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>

#include <VtkPipeline.h>
#include "QQuickVTKItem.h"

#include <QUrl>
#include <QFileInfo>

struct VtkContext : vtkObject {
    static VtkContext* New();
    vtkTypeMacro(VtkContext, vtkObject);
    vtkSmartPointer<vtkRenderer> renderer;
    vtkSmartPointer<vtkRenderWindow> renderWindow;
    vtkSmartPointer<vtkRenderWindowInteractor> interactor;
    std::vector<std::shared_ptr<VtkPipeline>> pipelines;
};

struct VtkQuickItem : public QQuickVTKItem {
    Q_OBJECT
    QML_ELEMENT
    public:
    std::mutex mux;
    std::thread _thread;
    std::atomic<bool> stop{false};
    QQuickVTKItem::vtkUserData _ctx;
    std::atomic<bool> camera_initialized{false};
    ~VtkQuickItem();
    Q_INVOKABLE void stop_load();
    Q_INVOKABLE void recolor_pass();
    Q_INVOKABLE void fit_to_cloud();
    Q_INVOKABLE void radius_outlier_removal();
    Q_INVOKABLE void load_point_cloud(QUrl filePath);
    void clear_scene();
    vtkSmartPointer<VtkContext> create_scene(vtkRenderWindow*);
    void syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline);
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
    signals:
    void distanceUpdated(int);
    void pointCloudUpdated(int, uint64_t, uint64_t);
};

#endif // VTKQUICKITEM_H