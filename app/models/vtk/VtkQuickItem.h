#ifndef VTKQUICKITEM_H
#define VTKQUICKITEM_H

#include <mutex>

#include <vtkObject.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>

#include <VtkPipeline.h>
#include "QQuickVTKItem.h"

#include <QUrl>
#include <QFileInfo>

struct VtkQuickItem : public QQuickVTKItem {
    Q_OBJECT
    QML_ELEMENT
    public:
    std::mutex mux;
    bool stop = false;
    std::thread _thread;
    bool camera_initialized;
    QQuickVTKItem::vtkUserData _ctx;
    ~VtkQuickItem();
    Q_INVOKABLE void stop_load() { stop = true; }
    Q_INVOKABLE void load_point_cloud(QUrl filePath);
    void clear_scene();
    void syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline);
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
    signals:
    void pointCloudProgress(int progress);
};

struct VtkContext : vtkObject {
    static VtkContext* New();
    vtkTypeMacro(VtkContext, vtkObject);
    vtkSmartPointer<vtkRenderer> renderer;
    vtkSmartPointer<vtkRenderWindow> renderWindow;
    vtkSmartPointer<vtkRenderWindowInteractor> interactor;
    std::vector<std::shared_ptr<VtkPipeline>> pipelines;
};

#endif // VTKQUICKITEM_H