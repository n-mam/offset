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
        auto pipeline =
            std::make_shared<PointCloudPipeline>();
        pipeline->addToRenderer(ctx->renderer);
        ctx->pipelines.push_back(pipeline);
        ctx->renderer->ResetCamera();
        return ctx;
}

void VtkQuickItem::clear_scene() {
    if (_thread.joinable()) {
        stop.store(true, std::memory_order_relaxed);
        _thread.join();
        stop.store(false, std::memory_order_relaxed);
    }
    auto pipeline = active_pipeline();
    if (pipeline) pipeline->reset();
    camera_initialized.store(false, std::memory_order_relaxed);
    context()->renderer->ResetCameraClippingRange();
    context()->renderWindow->Render();
}

void VtkQuickItem::syncToVTK(std::shared_ptr<PointCloudPipeline> pipeline) {
    auto& verts = pipeline->verts;
    auto& points = pipeline->points;
    auto& colors = pipeline->colors;
    auto& cloud = pipeline->svf.cloud;
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
    for (auto& key : pipeline->svf.dirty_voxels) {
        auto& voxel = pipeline->svf.voxel_map[key];
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
    pipeline->svf.dirty_voxels.clear();
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
        set_active_pipeline(base_pipeline());
        while (!stop.load(std::memory_order_relaxed) &&
            (bytes = rd->read_sync(buf.get(), _2M, total_bytes)) > 0) {
                total_bytes += bytes;
                auto pipeline = base_pipeline();
                auto v = pipeline->svf.consume_cloud_chunk(
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
                            syncToVTK(base_pipeline());
                            if (!camera_initialized.load(std::memory_order_relaxed)) {
                                context()->renderer->ResetCamera();
                                context()->renderer->ResetCameraClippingRange();
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
        auto pipeline = active_pipeline();
        if (pipeline->points->GetNumberOfPoints() == 0) return;
        context()->renderer->ResetCamera();
        context()->renderer->ResetCameraClippingRange();
        rw->Render();
    });
}

void VtkQuickItem::compute_color_map(const std::string& arrayName) {
    auto pipeline = active_pipeline();
    auto& cloud = pipeline->svf.cloud;

    const double min_z = pipeline->svf.min_z;
    const double max_z = pipeline->svf.max_z;
    const double denom = (max_z - min_z + 1e-9);
    const vtkIdType n = static_cast
        <vtkIdType>(cloud->points.size());
    vtkNew<vtkUnsignedCharArray> colors;
    colors->SetNumberOfComponents(3);
    colors->SetNumberOfTuples(n);
    colors->SetName(arrayName.c_str());
    for (vtkIdType i = 0; i < n; ++i) {
        const auto& p = cloud->points[i];
        double t = (p.z - min_z) / denom;
        t = std::clamp(t, 0.0, 1.0);
        unsigned char rgb[3] = {
            static_cast<unsigned char>(255 * t),
            static_cast<unsigned char>(255 * (1.0 - std::abs(t - 0.5) * 2)),
            static_cast<unsigned char>(255 * (1.0 - t))
        };
        colors->SetTypedTuple(i, rgb);
    }

    auto* pd = pipeline->polyData->GetPointData();
    // replace if it already exists
    pd->RemoveArray(arrayName.c_str());
    pd->AddArray(colors);
    pipeline->polyData->Modified();
}

void VtkQuickItem::apply_scalar(QString name) {
    auto arrayName = name.toStdString();
    std::thread([this, arrayName]{
        auto pipeline = active_pipeline();
        auto* pd = pipeline->polyData->GetPointData();
        if (!pd->HasArray(arrayName.c_str())) {
            compute_color_map(arrayName);
        }
        QMetaObject::invokeMethod(qApp, [this, arrayName]() {
            dispatch_async([this, arrayName](vtkRenderWindow* rw, vtkUserData ud) {
                std::lock_guard<std::mutex> lg(mux);
                auto pipeline = active_pipeline();
                auto* pd = pipeline->polyData->GetPointData();
                pd->SetActiveScalars(arrayName.c_str());
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

void VtkQuickItem::ground_z_depth() {
    std::thread([this](){
        auto* ctx = VtkContext::SafeDownCast(_ctx);
        auto pipeline = ctx->pipelines[0];
        std::lock_guard<std::mutex> lg(mux);
        pipeline->svf.ground_z_depth();
        update();
        dispatch_async([this](vtkRenderWindow* rw, vtkUserData ud) {
            auto* ctx = VtkContext::SafeDownCast(ud);
            syncToVTK(ctx->pipelines[0]);
        });
    }).detach();
}

VtkContext *
    VtkQuickItem::context() {
        return VtkContext::SafeDownCast(_ctx);
}

std::shared_ptr<PointCloudPipeline> 
    VtkQuickItem::base_pipeline() {
        auto* ctx = VtkContext::SafeDownCast(_ctx);
        if (!ctx || ctx->pipelines.empty()) return nullptr;        
        return ctx->pipelines[0];
}

std::shared_ptr<PointCloudPipeline> 
    VtkQuickItem::active_pipeline() {
        auto* ctx = VtkContext::SafeDownCast(_ctx);
        if (!ctx || ctx->pipelines.empty()) return nullptr;        
        return ctx->active_pipeline;
}

void VtkQuickItem::set_active_pipeline(
        std::shared_ptr<PointCloudPipeline> pipeline) {
    context()->active_pipeline = pipeline;
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