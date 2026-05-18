#ifndef VTKQUICKITEM_H
#define VTKQUICKITEM_H

#include <mutex>

#include <vtkObject.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>

#include <VtkPipeline.h>
#include "QQuickVTKItem.h"

struct VtkQuickItem : public QQuickVTKItem {
    Q_OBJECT
    QML_ELEMENT
    public:
    std::thread _thread;
    std::mutex mux;
    QQuickVTKItem::vtkUserData _ctx;
    ~VtkQuickItem();
    Q_INVOKABLE void load_point_cloud(QString filePath);
    void syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline);
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
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