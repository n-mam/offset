#include <VtkQuickItem.h>

#include <vtkNew.h>
#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkRenderWindow.h>
#include <vtkPolyDataMapper.h>

#include <MouseInteractor.h>

// ============================================================
// Scene creation
// ============================================================
auto create_scene(vtkRenderWindow* renderWindow) {
    auto ctx = vtkSmartPointer<VtkContext>::New();
    vtkNew<vtkNamedColors> colors;
    // --------------------------------------------------------
    // Core renderer setup
    // --------------------------------------------------------
    ctx->renderer = vtkSmartPointer<vtkRenderer>::New();
    ctx->renderWindow = renderWindow;
    renderWindow->SetSize(800, 600);
    renderWindow->SetWindowName(
        "VTK Multi Pipeline Scene");
    renderWindow->AddRenderer(ctx->renderer);
    ctx->renderer->SetBackground(0,0,0);
    // --------------------------------------------------------
    // Interactor
    // --------------------------------------------------------
    ctx->interactor =
        renderWindow->GetInteractor();
    vtkNew<MouseInteractorHighLightActor> style;
    style->SetDefaultRenderer(ctx->renderer);
    ctx->interactor->SetInteractorStyle(style);
    // --------------------------------------------------------
    // Point cloud pipeline
    // --------------------------------------------------------
    auto pointCloud =
        std::make_shared<PointCloudPipeline>();
    pointCloud->addToRenderer(ctx->renderer);
    ctx->pipelines.push_back(pointCloud);
    // --------------------------------------------------------
    // Sphere pipeline
    // --------------------------------------------------------
    // auto spheres =
    //     std::make_shared<SpherePipeline>(10);
    // spheres->addToRenderer(ctx->renderer);
    // ctx->pipelines.push_back(spheres);
    // --------------------------------------------------------
    // Camera
    // --------------------------------------------------------
    ctx->renderer->ResetCamera();
    return ctx;
}

// ============================================================
// QQuickVTKItem entry point
// ============================================================
QQuickVTKItem::vtkUserData
    VtkQuickItem::initializeVTK(vtkRenderWindow *renderWindow) {
        return create_scene(renderWindow);
}

void VtkQuickItem::load_point_cloud(QString filePath) {
    dispatch_async(
        [filePath](
            vtkRenderWindow* renderWindow, vtkUserData ud) {
            auto* ctx =
                VtkContext::SafeDownCast(ud);
            if (!ctx) return;
            auto pointCloud =
                std::dynamic_pointer_cast<
                    PointCloudPipeline>(
                        ctx->pipelines[0]);
            if (!pointCloud) return;
            if (!pointCloud->loadXYZ(
                    filePath.toStdString())) {
                return;
            }
            pointCloud->syncToVTK();
            ctx->renderer->ResetCamera();
            renderWindow->Render();
        });
}

vtkStandardNewMacro(VtkContext);