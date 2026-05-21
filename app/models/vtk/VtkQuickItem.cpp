#include <vtkNew.h>
#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkRenderWindow.h>
#include <vtkPolyDataMapper.h>

#include <VtkQuickItem.h>
#include <MouseInteractor.h>

// ============================================================
// Scene creation
// ============================================================
auto create_scene(vtkRenderWindow* renderWindow) {
    auto ctx = vtkSmartPointer<VtkContext>::New();
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
    auto cloud = pipeline->pcl_svf.pcl_cloud;
    auto points = pipeline->points;
    auto verts = pipeline->verts;
    auto colors = pipeline->colors;
    const vtkIdType total_points = static_cast<vtkIdType>(cloud->points.size());
    // Grow vtk arrays only when needed
    if (points->GetNumberOfPoints() != total_points) {
        vtkIdType old_count = points->GetNumberOfPoints();
        points->SetNumberOfPoints(total_points);
        colors->SetNumberOfTuples(total_points);
        // Create verts ONLY for new points
        for (vtkIdType i = old_count; i < total_points; ++i) {
            verts->InsertNextCell(1);
            verts->InsertCellPoint(i);
        }
    }
    for (auto& [key, voxel] : pipeline->pcl_svf.voxel_map) {
        if (!voxel.changed) continue;
        const auto& p = cloud->points[voxel.point_index];
        const vtkIdType idx = static_cast<vtkIdType>(voxel.point_index);
        // Update point position
        points->SetPoint(idx, p.x, p.y, p.z);
        // Update color
        unsigned char rgb[3] = {
            static_cast<unsigned char>(voxel.sr),
            static_cast<unsigned char>(voxel.sg),
            static_cast<unsigned char>(voxel.sb)
        };
        colors->SetTypedTuple(idx, rgb);
        voxel.changed = false;
    }
    points->Modified();
    verts->Modified();
    colors->Modified();
    pipeline->polyData->Modified();
}

void VtkQuickItem::load_point_cloud(QUrl path) {
    QFile file(path.toLocalFile());
    QFileInfo fileInfo(file);
    QString filepath = fileInfo.absoluteFilePath();
    std::thread([this, path = filepath.toStdString()](){
        auto rd = npl::make_file(path);
        if (!rd) return;
        auto buf = std::make_unique<uint8_t []>(_2M);
        ssize_t bytes, total_bytes = 0;
        size_t chunk_counter = 0;
        while ((bytes = rd->read_sync(buf.get(), _2M, total_bytes)) > 0) {
            total_bytes += bytes;
            auto* ctx = VtkContext::SafeDownCast(_ctx);
            auto pipeline =
                std::dynamic_pointer_cast<
                    PointCloudPipeline>(
                        ctx->pipelines[0]);
            {
                std::lock_guard<std::mutex> lg(mux);
                pipeline->pcl_svf.consume_point_cloud_chunk(buf.get(), bytes);
            }
            if (chunk_counter % 20 == 0) {
                // QMetaObject::invoke queues the execution on the main thread event
                // loop at a later point while dispatch_async() is a frame-synchronized
                // renders-safe scheduling primitive which schedules the execution correctly
                // inside Qt Quick’s scene graph lifecycle. both execute on the main UI
                // thread but dispatch_async is executed at the correct time.
                auto ok = QMetaObject::invokeMethod(qApp, [this](){
                    update();
                    // need a hop back to the GUI thread first else we'd get
                    // Warning: Updates can only be scheduled from GUI thread
                    // or from QQuickItem::updatePaintNode()
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
                        syncToVTK(pipeline);
                        if (!camera_initialized) {
                            ctx->renderer->ResetCamera();
                            ctx->renderer->ResetCameraClippingRange();
                            camera_initialized = true;
                        }
                    });
                }, Qt::QueuedConnection);
            }
            std::cout << ++chunk_counter << std::endl;
        }
    }).detach();
}

// ============================================================
// QQuickVTKItem entry point
// ============================================================
QQuickVTKItem::vtkUserData
    VtkQuickItem::initializeVTK(vtkRenderWindow *renderWindow) {
        return _ctx = create_scene(renderWindow);
}

VtkQuickItem::~VtkQuickItem() {
    // if (_thread.joinable()) {
    //     _thread.join();
    // }
}

vtkStandardNewMacro(VtkContext);