#ifndef VTKQUICKITEM_H
#define VTKQUICKITEM_H

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
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
    Q_INVOKABLE void load_point_cloud(QString filePath);
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