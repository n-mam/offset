#include <vtkNew.h>
#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkRenderWindow.h>
#include <vtkPolyDataMapper.h>

#include <VtkQuickItem.h>
#include <MouseInteractor.h>

vtkSmartPointer<VtkContext>
    VtkQuickItem::create_scene(vtkRenderWindow* renderWindow) {
        auto ctx = vtkSmartPointer<VtkContext>::New();
        // Core renderer setup
        ctx->renderer = vtkSmartPointer<vtkRenderer>::New();
        ctx->renderWindow = renderWindow;
        renderWindow->SetSize(800, 600);
        renderWindow->SetWindowName(
            "VTK Multi Pipeline Scene");
        renderWindow->AddRenderer(ctx->renderer);
        ctx->renderer->SetBackground(0,0,0);
        // Interactor
        ctx->interactor =
            renderWindow->GetInteractor();
        vtkNew<PointPickerDistanceStyle> style;
        style->SetDefaultRenderer(ctx->renderer);
        style->cbk = [this](int distance){
            distanceUpdated(distance);
        };
        ctx->interactor->SetInteractorStyle(style);
        // Point cloud pipeline
        auto pointCloud =
            std::make_shared<PointCloudPipeline>();
        pointCloud->addToRenderer(ctx->renderer);
        ctx->pipelines.push_back(pointCloud);
        // Sphere pipeline
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

void VtkQuickItem::clear_scene() {
    if (_thread.joinable()) {
        stop.store(true, std::memory_order_relaxed);
        _thread.join();
        stop.store(false, std::memory_order_relaxed);
    }
    auto* ctx = VtkContext::SafeDownCast(_ctx);
    auto pipeline = std::static_pointer_cast
        <PointCloudPipeline>(ctx->pipelines[0]);
    pipeline->reset();
    camera_initialized.store(false, std::memory_order_relaxed);
    ctx->renderer->ResetCameraClippingRange();
    ctx->renderWindow->Render();
}

void VtkQuickItem::syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline) {
    auto& verts = pipeline->verts;
    auto& points = pipeline->points;
    auto& colors = pipeline->colors;
    auto& cloud = pipeline->pcl_svf.pcl_cloud;
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
    for (auto& key : pipeline->pcl_svf.dirty_voxels) {
        auto& voxel = pipeline->pcl_svf.voxel_map[key];
        const auto& p = cloud->points[voxel.point_index];
        const vtkIdType idx = static_cast<vtkIdType>(voxel.point_index);
        // update position
        points->SetPoint(idx, p.x, p.y, p.z);
        // update color
        double inv = 1.0 / voxel.count;
        unsigned char rgb[3] = {
            static_cast<unsigned char>(voxel.sr * inv),
            static_cast<unsigned char>(voxel.sg * inv),
            static_cast<unsigned char>(voxel.sb * inv)
        };
        voxel.dirty = false;
        colors->SetTypedTuple(idx, rgb);
    }
    points->Modified();
    verts->Modified();
    colors->Modified();
    pipeline->polyData->Modified();
    pipeline->pcl_svf.dirty_voxels.clear();
}

void VtkQuickItem::load_point_cloud(QUrl path) {
    constexpr qint64 chunkSize = _2M;
    const QFileInfo fileInfo(path.toLocalFile());
    const qint64 fileSize = fileInfo.size();
    auto filePath = fileInfo.absoluteFilePath().toStdString();
    clear_scene(); // clear existing cloud
    _thread = std::thread([this, fileSize, filePath](){
        auto rd = npl::make_file(filePath);
        if (!rd) return;
        uint64_t total_points = 0, total_voxels = 0;
        auto buf = std::make_unique<uint8_t []>(_2M);
        ssize_t bytes, total_bytes = 0, chunks = 0;
        std::vector<ParsedPoint> parsed_points;
        parsed_points.reserve(4*1024*1024);
        while (!stop.load(std::memory_order_relaxed) &&
            (bytes = rd->read_sync(buf.get(), _2M, total_bytes)) > 0) {
                total_bytes += bytes;
                auto* ctx = VtkContext::SafeDownCast(_ctx);
                auto pipeline = std::static_pointer_cast
                        <PointCloudPipeline>(ctx->pipelines[0]);
                auto v = pipeline->pcl_svf.consume_cloud_chunk(
                    buf.get(), bytes, parsed_points, mux);
                total_voxels += v;
                total_points += parsed_points.size();
                double percent = (double(total_bytes) / double(fileSize)) * 100.0;
                if (chunks % 20 == 0) {
                    // QMetaObject::invoke queues the execution on the main thread event
                    // loop at a later point while dispatch_async() is a frame-synchronized
                    // renders-safe scheduling primitive which schedules the execution correctly
                    // inside Qt Quick’s scene graph lifecycle. both execute on the main UI
                    // thread but dispatch_async is executed at the correct time.
                    QMetaObject::invokeMethod(qApp, [this, percent, total_points, total_voxels](){
                        update();
                        // need a hop back to the GUI thread first else we'd get
                        // Warning: Updates can only be scheduled from GUI thread
                        // or from QQuickItem::updatePaintNode()
                        dispatch_async([this](vtkRenderWindow* renderWindow, vtkUserData ud) {
                            std::lock_guard<std::mutex> lg(mux);
                            auto* ctx = VtkContext::SafeDownCast(ud);
                            if (!ctx) return;
                            auto pipeline = std::static_pointer_cast
                                <PointCloudPipeline>(ctx->pipelines[0]);
                            // Notify VTK pipeline
                            syncToVTK(pipeline);
                            if (!camera_initialized.load(std::memory_order_relaxed)) {
                                ctx->renderer->ResetCamera();
                                ctx->renderer->ResetCameraClippingRange();
                                camera_initialized.store(true, std::memory_order_relaxed);
                            }
                        });
                        emit pointCloudUpdated(percent, total_points, total_voxels);
                    }, Qt::QueuedConnection);
                }
        }
    });
}

void VtkQuickItem::fit_to_cloud() {
    update();
    dispatch_async([this](vtkRenderWindow* rw, vtkUserData ud) {
        auto* ctx = VtkContext::SafeDownCast(ud);
        if (!ctx) return;
        auto pipeline = std::static_pointer_cast
            <PointCloudPipeline>(ctx->pipelines[0]);
        if (pipeline->points->GetNumberOfPoints() == 0) return;
        ctx->renderer->ResetCamera();
        ctx->renderer->ResetCameraClippingRange();
        rw->Render();
    });
}

void VtkQuickItem::recolor_pass() {
    std::thread([this]() {
        auto* ctx = VtkContext::SafeDownCast(_ctx);
        if (!ctx || ctx->pipelines.empty()) return;
        auto pipeline = std::static_pointer_cast
            <PointCloudPipeline>(ctx->pipelines[0]);
        auto& cloud  = pipeline->pcl_svf.pcl_cloud;
        auto& colors = pipeline->colors;
        const double min_z = pipeline->pcl_svf.min_z;
        const double max_z = pipeline->pcl_svf.max_z;
        const double denom = (max_z - min_z + 1e-9);
        const vtkIdType n = static_cast<vtkIdType>(cloud->points.size());
        // compute off-thread
        std::vector<std::array<unsigned char, 3>> computed_colors;
        computed_colors.resize(n);
        for (vtkIdType i = 0; i < n; ++i) {
            const auto& p = cloud->points[i];
            double t = (p.z - min_z) / denom;
            t = std::clamp(t, 0.0, 1.0);
            unsigned char rgb[3] = {
                static_cast<unsigned char>(255 * t),
                static_cast<unsigned char>(255 * (1.0 - std::abs(t - 0.5) * 2)),
                static_cast<unsigned char>(255 * (1.0 - t))
            };
            computed_colors[i] = {rgb[0], rgb[1], rgb[2]};
        }
        QMetaObject::invokeMethod(qApp, [this, computed_colors = std::move(computed_colors)](){
            // push to render thread
            dispatch_async([this, computed_colors = std::move(computed_colors)]
                        (vtkRenderWindow* rw, vtkUserData ud) {
                std::lock_guard<std::mutex> lg(mux);
                auto* ctx = VtkContext::SafeDownCast(ud);
                if (!ctx || ctx->pipelines.empty()) return;
                auto pipe = std::static_pointer_cast
                    <PointCloudPipeline>(ctx->pipelines[0]);
                auto& colors = pipe->colors;
                const vtkIdType n = static_cast<vtkIdType>(computed_colors.size());
                for (vtkIdType i = 0; i < n; ++i) {
                    colors->SetTypedTuple(i, computed_colors[i].data());
                }
                colors->Modified();
                pipe->polyData->Modified();
                rw->Render();
            });
        }, Qt::QueuedConnection);
    }).detach();
}

// QQuickVTKItem entry point
QQuickVTKItem::vtkUserData
    VtkQuickItem::initializeVTK(vtkRenderWindow *renderWindow) {
        return _ctx = create_scene(renderWindow);
}

void VtkQuickItem::radius_outlier_removal() {
    std::thread([this](){
        auto* ctx = VtkContext::SafeDownCast(_ctx);
        auto pipeline = std::static_pointer_cast
            <PointCloudPipeline>(ctx->pipelines[0]);
        std::lock_guard<std::mutex> lg(mux);
        pipeline->pcl_svf.radius_outlier_removal(5.0f, 6);
        update();
        dispatch_async([this](vtkRenderWindow* rw, vtkUserData ud) {
            auto* ctx = VtkContext::SafeDownCast(ud);
            auto pipeline = std::static_pointer_cast
                <PointCloudPipeline>(ctx->pipelines[0]);
            syncToVTK(pipeline);
            std::cout << "done..." << std::endl;
        });
    }).detach();
}

void VtkQuickItem::stop_load() {
    stop.store(true, std::memory_order_relaxed);
}

VtkQuickItem::~VtkQuickItem() {
    stop.store(true, std::memory_order_relaxed);
    if (_thread.joinable()) {
        _thread.join();
    }
}

vtkStandardNewMacro(VtkContext);