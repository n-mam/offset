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

void VtkQuickItem::syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline) {
    std::lock_guard<std::mutex> lg(mux);
    auto cloud = pipeline->pcl_svf.pcl_cloud;
    // Copy changed PCL points into VTK
    pipeline->points->SetNumberOfPoints(
        static_cast<vtkIdType>(
            cloud->points.size()));
    //loop through changed/added voxel data elements and update themto vtk 
    // todo
}

void VtkQuickItem::load_point_cloud(QString filepath) {
    std::thread([this, path = filepath.toStdString()](){
        auto rd = npl::make_file(path);
        uint8_t *buf = (uint8_t *)calloc(_1M, 1);
        ssize_t bytes;
        size_t chunk_counter = 0;
        while ((bytes = rd->read_sync(buf, _1M, 0)) > 0) {
            auto* ctx = VtkContext::SafeDownCast(_ctx);
            auto pipeline =
                std::dynamic_pointer_cast<
                    PointCloudPipeline>(
                        ctx->pipelines[0]);
            pipeline->pcl_svf.consume_point_cloud_chunk(buf, bytes);
            syncToVTK(pipeline);
            chunk_counter++;
            if (chunk_counter % 10 == 0) {
                // QMetaObject::invoke queues the execution on the main thread event  
                // loop at a later point while dispatch_async() is a frame-synchronized
                // renders-safe scheduling primitive which schedules the execution correctly 
                // inside Qt Quick’s scene graph lifecycle. both execute on the main UI 
                // thread but dispatch_async is executed at the correct time.
                dispatch_async([this](vtkRenderWindow* renderWindow, vtkUserData ud) {
                    std::lock_guard<std::mutex> lg(mux);
                    auto* ctx = VtkContext::SafeDownCast(ud);
                    if (!ctx) return;
                    auto pipeline =
                        std::dynamic_pointer_cast<
                            PointCloudPipeline>(
                                ctx->pipelines[0]);
                    if (!pipeline) return;
                    // Notify VTK pipeline 
                    pipeline->points->Modified();
                    pipeline->polyData->Modified();
                    pipeline->glyphFilter->Update();
                    pipeline->polyData->ComputeBounds();
                    //pointCloud->syncToVTK();
                    ctx->renderer->ResetCamera();
                    ctx->renderWindow->Render();
                });
            }
        }
        return;
    }).detach();
}

// ============================================================
// QQuickVTKItem entry point
// ============================================================
QQuickVTKItem::vtkUserData
    VtkQuickItem::initializeVTK(vtkRenderWindow *renderWindow) {
        return _ctx = create_scene(renderWindow);
}

vtkStandardNewMacro(VtkContext);