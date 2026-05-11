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
    auto ctx = vtkNew<VtkContext>();
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
    ctx->renderer->SetBackground(
        colors->GetColor3d("SteelBlue").GetData());
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
    pointCloud->loadXYZ("/home/nmam/cube.xyz");
    pointCloud->addToRenderer(ctx->renderer);
    ctx->pipelines.push_back(pointCloud);
    // --------------------------------------------------------
    // Sphere pipeline
    // --------------------------------------------------------
    auto spheres =
        std::make_shared<SpherePipeline>(10);
    spheres->addToRenderer(ctx->renderer);
    ctx->pipelines.push_back(spheres);
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

vtkStandardNewMacro(VtkContext);