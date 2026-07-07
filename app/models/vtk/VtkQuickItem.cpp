#include <vtkNew.h>
#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkAxesActor.h>
#include <vtkMatrix4x4.h>
#include <vtkTransform.h>
#include <vtkRenderWindow.h>
#include <vtkPolyDataMapper.h>

#include <pcl/PointIndices.h>
#include <pcl/ModelCoefficients.h>
#include <pcl/filters/extract_indices.h>
#include <pcl/segmentation/sac_segmentation.h>
#include <pcl/segmentation/progressive_morphological_filter.h>

#include <VtkQuickItem.h>
#include <mouse.interactor.h>

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
        // base pipeline
        auto pipeline = std::make_shared<vis::pipeline>
            (vis::filter::base);
        pipeline->addActorsToRenderer(ctx->renderer);
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
    vtkNew<vtkTransform> transform;
    transform->Translate(0.0, 0.0, 0.0);
    vtkNew<vtkAxesActor> axes;
    axes->SetUserTransform(transform);
    axes->SetTotalLength(50.0, 50.0, 50.0); 
    axes->SetShaftTypeToCylinder();
    axes->SetCylinderRadius(0.005);
    axes->SetConeRadius(0.2);
    context()->renderer->AddActor(axes);
}

void VtkQuickItem::syncToVTK(sppl pipeline) {
    auto& verts = pipeline->verts;
    auto& points = pipeline->points;
    auto& colors = pipeline->colors;
    auto& cloud = pipeline->svf.cloud;
    const vtkIdType total_points = 
        static_cast<vtkIdType>(cloud->points.size());
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
        std::vector<parsed_point> parsed_points;
        parsed_points.reserve(4*1024*1024);
        auto pipeline = base_pipeline();
        while (!stop.load(std::memory_order_relaxed) &&
            (bytes = rd->read_sync(buf.get(), _2M, total_bytes)) > 0) {
                total_bytes += bytes;
                auto v = pipeline->svf.consume_cloud_chunk(
                    buf.get(), bytes, parsed_points, mux);
                //++chunks;
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
        QMetaObject::invokeMethod(qApp, [this, total_points, total_voxels]() {
            dispatch_async([this](vtkRenderWindow* renderWindow, vtkUserData ud) {
                // runs after render event loop cycles
                // make base as the active pipeline
                context()->active_pipeline = base_pipeline();
                cloud_loaded.store(true, std::memory_order_relaxed);
            });
            if (stop.load(std::memory_order_relaxed)) {
                emit pointCloudUpdated(100, total_points, total_voxels);
            }
        }, Qt::QueuedConnection);
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
    if (!has_cloud()) return;
    auto arrayName = name.toStdString();
    std::thread([this, arrayName]{
        auto pipeline = active_pipeline();
        if (!pipeline || pipeline->is_empty()) return;
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

sppl VtkQuickItem::build_filtered_pipeline(sppl source,
        const std::vector<int>& indices, vis::filter filter_type) {
    if (!source || indices.empty()) return nullptr;
    auto result = std::make_shared<vis::pipeline>(filter_type);
    auto& input_cloud = source->svf.cloud;
    auto& voxels = source->svf.voxel_map;
    result->svf.voxel_map.reserve(indices.size());
    result->svf.cloud->points.reserve(indices.size());
    result->svf.dirty_voxels.reserve(indices.size());
    vtkIdType newIndex = 0;
    for (int idx : indices) {
        if (idx < 0 || static_cast<size_t>(idx) >= input_cloud->size())
            continue;
        const auto& p = input_cloud->points[idx];
        voxel_key key{
            static_cast<int>(std::floor(p.x / source->svf.voxel_size)),
            static_cast<int>(std::floor(p.y / source->svf.voxel_size)),
            static_cast<int>(std::floor(p.z / source->svf.voxel_size))
        };
        auto it = voxels.find(key);
        if (it == voxels.end()) continue;
        const auto& src_voxel = it->second;
        auto [new_it, inserted] =
            result->svf.voxel_map.try_emplace(key);
        if (!inserted) continue;
        auto& dst = new_it->second;
        dst.sx = src_voxel.sx;
        dst.sy = src_voxel.sy;
        dst.sz = src_voxel.sz;
        dst.sr = src_voxel.sr;
        dst.sg = src_voxel.sg;
        dst.sb = src_voxel.sb;
        dst.dirty = true;
        dst.count = src_voxel.count;
        dst.point_index = newIndex++;
        result->svf.cloud->push_back(p);
        result->svf.dirty_voxels.push_back(key);
    }
    return result;
}

void VtkQuickItem::elevation_filter_ransac() {
    if (!has_cloud()) return;
    auto cached = get_pipeline(vis::filter::ransac);
    if (cached) {
        set_active_pipeline(cached);
        return;
    }
    std::thread([this]() {
        auto source = active_pipeline();
        if (!source || source->is_empty()) return;
        using PointT = pcl::PointXYZ;
        pcl::PointIndices::Ptr inliers(new pcl::PointIndices);
        pcl::ModelCoefficients::Ptr coefficients(
            new pcl::ModelCoefficients);
        pcl::SACSegmentation<PointT> seg;
        seg.setOptimizeCoefficients(true);
        seg.setModelType(pcl::SACMODEL_PLANE);
        seg.setMethodType(pcl::SAC_RANSAC);
        seg.setMaxIterations(100);
        seg.setDistanceThreshold(0.2f);
        seg.setInputCloud(source->svf.cloud);
        seg.segment(*inliers, *coefficients);
        if (inliers->indices.empty()) return;
        auto filter = build_filtered_pipeline(
            source, inliers->indices, vis::filter::ransac);
        activate_pipeline_async(filter);
    }).detach();
}

void VtkQuickItem::elevation_filter_pmf() {
    if (!has_cloud()) return;
    auto cached = get_pipeline(vis::filter::pmf);
    if (cached) {
        set_active_pipeline(cached);
        return;
    }
    std::thread([this]() {
        auto source = active_pipeline();
        if (!source || source->is_empty()) return;
        using PointT = pcl::PointXYZ;
        pcl::PointIndices ground;
        pcl::ProgressiveMorphologicalFilter<PointT> pmf;
        pmf.setInputCloud(source->svf.cloud);
        pmf.setMaxWindowSize(10);
        pmf.setSlope(0.5f);
        pmf.setInitialDistance(0.2f);
        pmf.setMaxDistance(1.0f);
        pmf.extract(ground.indices);
        if (ground.indices.empty()) return;
        auto filter = build_filtered_pipeline(
            source, ground.indices, vis::filter::pmf);
        activate_pipeline_async(filter);
    }).detach();
}

void VtkQuickItem::activate_pipeline_async(sppl pipeline) {
    if (!pipeline) return;
    QMetaObject::invokeMethod(qApp, [this, pipeline]() {
        update();
        dispatch_async([this, pipeline] (vtkRenderWindow* rw, vtkUserData ud) {
            std::lock_guard<std::mutex>lg(mux);
            syncToVTK(pipeline);
            set_active_pipeline(pipeline);
        });
    }, Qt::QueuedConnection);
}

void VtkQuickItem::fit_to_cloud() {
    update();
    dispatch_async([this](vtkRenderWindow* rw, vtkUserData ud) {
        context()->renderer->ResetCamera();
        context()->renderer->ResetCameraClippingRange();
        rw->Render();
    });
}

VtkContext *
    VtkQuickItem::context() {
        return VtkContext::SafeDownCast(_ctx);
}

sppl VtkQuickItem::base_pipeline() {
    auto* ctx = VtkContext::SafeDownCast(_ctx);
    if (!ctx || ctx->pipelines.empty()) return nullptr;
    return ctx->pipelines[0];
}

sppl VtkQuickItem::active_pipeline() {
    auto* ctx = VtkContext::SafeDownCast(_ctx);
    if (!ctx || ctx->pipelines.empty()) return nullptr;
    return ctx->active_pipeline;
}

void VtkQuickItem::set_active_pipeline(sppl pipeline) {
    if (!pipeline) return;
    auto active = active_pipeline();
    if (!active) return;
    if (active == pipeline) return;
    auto ctx = context();
    active->removeActorsFromRenderer(ctx->renderer);
    ctx->active_pipeline = pipeline;
    pipeline->addActorsToRenderer(ctx->renderer);
    auto it = std::ranges::find_if(ctx->pipelines, 
        [&](const sppl& p) {
            return p == pipeline;
        });
    if (it == ctx->pipelines.end()) {
        ctx->pipelines.push_back(pipeline);
    }
    ctx->renderer->ResetCamera();
}

void VtkQuickItem::restore_base_pipeline() {
    if (!has_cloud()) return;
    auto base = base_pipeline();
    auto active = active_pipeline();    
    if (!base || base->is_empty()) return;
    if (!active || active->is_empty()) return;
    if (base == active) return;
    auto ctx = context();
    active->removeActorsFromRenderer(ctx->renderer);
    ctx->active_pipeline = base;
    base->addActorsToRenderer(ctx->renderer);
    ctx->renderer->ResetCamera();    
}

sppl VtkQuickItem::get_pipeline(vis::filter f) {
    for (const auto& pipeline : context()->pipelines) {
        if (pipeline->_filter == f) 
            return pipeline;
    }
    return nullptr;
}

bool VtkQuickItem::has_cloud() {
    return cloud_loaded.load(std::memory_order_relaxed);
}

void VtkQuickItem::stop_load() {
    stop.store(true, std::memory_order_relaxed);
}

void VtkQuickItem::start_imu_visualization(QString source) {
    if (!has_cloud()) return;
    auto active = active_pipeline();
    if (!active || active->is_empty()) return;    
    QString portName;
    source = source.trimmed();
    // If the source is only digits
    // treat it as a COM port number
    bool ok = false;
    int portNum = source.toInt(&ok);
    if (ok) {
        portName = QString("COM%1").arg(portNum);
    } else if (source.startsWith("COM", Qt::CaseInsensitive)) {
        // If it already starts with 
        // "COM", normalize the case
        portName = source.toUpper();
    } else {
        // Otherwise assume it's something else (UDP, etc.)
        qWarning() << "Unsupported source:" << source;
        return;
    }
    _serial = new SerialPortManager(portName);
    _serialThread = new QThread(this);
    _serial->moveToThread(_serialThread);
    connect(_serialThread, &QThread::started,
        _serial, &SerialPortManager::start);
    _serial->set_read_callback(
        [this](const QByteArray& line){
            onReadSerialLine(line);
        });
    connect(_serialThread, &QThread::finished,
        _serial, &QObject::deleteLater);
    _serialThread->start();
}

void VtkQuickItem::onReadSerialLine(const QByteArray& line) {
    imu::sample s;
    QByteArray clean = line.trimmed();
    auto fields = clean.split(',');
    if (fields.size() != 7) return;
    bool ok;
    QByteArray tsStr = fields[0].trimmed();
    tsStr = tsStr.replace("\r", "").replace("\n", "");
    s.ts_ms = tsStr.toULongLong(&ok);
    if (!ok) return;
    s.ax = fields[1].toDouble(&ok); if (!ok) return;
    s.ay = fields[2].toDouble(&ok); if (!ok) return;
    s.az = fields[3].toDouble(&ok); if (!ok) return;
    s.gx = fields[4].toDouble(&ok); if (!ok) return;
    s.gy = fields[5].toDouble(&ok); if (!ok) return;
    s.gz = fields[6].toDouble(&ok); if (!ok) return;  
    _orientation.update(s);
    QMetaObject::invokeMethod(qApp, [this]() {
        update();
        dispatch_async([this](vtkRenderWindow* rw, vtkUserData) {
            std::lock_guard<std::mutex> lg(mux);
            applyQuaternion(_orientation.get_quaternion());
            rw->Render();
        });        
    }, Qt::QueuedConnection);    
}

void VtkQuickItem::applyQuaternion(const imu::quaternion& q) {
    auto pipeline = active_pipeline();
    if (!pipeline || pipeline->actors.empty()) return;
    auto actor = pipeline->actors.front();
    const double xx = q.x * q.x;
    const double yy = q.y * q.y;
    const double zz = q.z * q.z;
    const double xy = q.x * q.y;
    const double xz = q.x * q.z;
    const double yz = q.y * q.z;
    const double wx = q.w * q.x;
    const double wy = q.w * q.y;
    const double wz = q.w * q.z;
    vtkNew<vtkMatrix4x4> m;
    m->Identity();
    m->SetElement(0,0,1 - 2*(yy + zz));
    m->SetElement(0,1,2*(xy - wz));
    m->SetElement(0,2,2*(xz + wy));
    m->SetElement(1,0,2*(xy + wz));
    m->SetElement(1,1,1 - 2*(xx + zz));
    m->SetElement(1,2,2*(yz - wx));
    m->SetElement(2,0,2*(xz - wy));
    m->SetElement(2,1,2*(yz + wx));
    m->SetElement(2,2,1 - 2*(xx + yy));
    vtkNew<vtkTransform> t;
    t->SetMatrix(m);
    actor->SetUserTransform(t);
}

void VtkQuickItem::stop_imu_visualization() {
    if (!_serialThread) return;
    QMetaObject::invokeMethod(_serial,
        &SerialPortManager::stop, Qt::BlockingQueuedConnection);
    _serialThread->quit();
    _serialThread->wait();
    delete _serialThread;
    _serial = nullptr;
    _serialThread = nullptr;
}

VtkQuickItem::~VtkQuickItem() {
    stop_imu_visualization();
    stop.store(true, std::memory_order_relaxed);
    if (_thread.joinable()) {
        _thread.join();
    }
}

// QQuickVTKItem entry point
QQuickVTKItem::vtkUserData
    VtkQuickItem::initializeVTK(vtkRenderWindow *renderWindow) {
        return _ctx = create_scene(renderWindow);
}

vtkStandardNewMacro(VtkContext);