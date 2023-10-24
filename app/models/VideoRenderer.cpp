#include <VideoRenderer.h>

#include <QMutexLocker>
#include <QRandomGenerator>
#include <QSGSimpleRectNode>
#include <QSGSimpleTextureNode>

VideoRenderer::VideoRenderer(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(QQuickItem::ItemHasContents, true);
    m_camera = std::make_shared<cvl::camera>();
}

VideoRenderer::~VideoRenderer()
{
    stop();
    if (m_texture != nullptr) {
        delete m_texture;
        m_texture = nullptr;
    }
    if (m_newTexture != nullptr) {
        delete m_newTexture;
        m_newTexture = nullptr;
    }
}

void VideoRenderer::componentComplete()
{
    QQuickItem::componentComplete();
}

void VideoRenderer::stop()
{
    m_timer.stop();
    m_camera->stop();
}

void VideoRenderer::start()
{
    if (!getSource().isEmpty()) {
        m_camera->start(
            [this](const cv::Mat& f_in){
                cv::Mat scaled_down;
                cv::resize(f_in, scaled_down, cv::Size(), getScaleF(), getScaleF(), cv::INTER_LINEAR);
                QMetaObject::invokeMethod(this,
                    [this, f = scaled_down.clone()](){
                        updateFrame(f);
                    }, Qt::QueuedConnection);
            });
    }
    else {
        connect(&m_timer, &QTimer::timeout, this, &VideoRenderer::updateStatic);
        m_timer.start(100);
    }
}

void VideoRenderer::updateStatic()
{
    createStatic();
    update();
}

void VideoRenderer::updateFrame(const cv::Mat& frame)
{
    createImageFromMat(frame);
    update();
}

void VideoRenderer::createImageFromMat(const cv::Mat& frame)
{
    if (m_newTexture == nullptr) {
        auto img = MatToQImage(frame);
        auto wnd = window();
        if (wnd != nullptr) {
            m_newTexture = wnd->createTextureFromImage(img);
        }
    }
}

QImage VideoRenderer::MatToQImage(const cv::Mat& mat)
{
    // 8-bits unsigned, NO. OF CHANNELS=1
    if(mat.type()==CV_8UC1)
    {
        // Set the color table (used to translate colour indexes to qRgb values)
        QVector<QRgb> colorTable;
        for (int i = 0; i < 256; i++)
            colorTable.push_back(qRgb(i,i,i));
        // Copy input Mat
        const uchar *qImageBuffer = (const uchar*)mat.data;
        // Create QImage with same dimensions as input Mat
        QImage img(qImageBuffer, mat.cols, mat.rows, mat.step, QImage::Format_Indexed8);
        img.setColorTable(colorTable);
        return img;
    }
    // 8-bits unsigned, NO. OF CHANNELS=3
    if(mat.type()==CV_8UC3)
    {
        // Copy input Mat
        const uchar *qImageBuffer = (const uchar*)mat.data;
        // Create QImage with same dimensions as input Mat
        QImage img(qImageBuffer, mat.cols, mat.rows, mat.step, QImage::Format_RGB888);
        return img.rgbSwapped();
    }
    return QImage();
}

QSGNode *VideoRenderer::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto node = static_cast<QSGSimpleTextureNode *>(oldNode);

    if (!node) {
        if (m_newTexture != nullptr) {
            node = new QSGSimpleTextureNode();
        }
    }

    if (node) {
        node->setRect(boundingRect() - QMarginsF(1,1,1,1));
        if (m_newTexture != nullptr) {
            if (m_texture != nullptr) {
                delete m_texture;
                m_texture = nullptr;
            }
            m_texture = m_newTexture;
            m_newTexture = nullptr;
            node->setTexture(m_texture);
        }
    }

    return node;
}

void VideoRenderer::createStatic()
{
    if (m_newTexture == nullptr) {
        QRandomGenerator::global()->fillRange(m_buffer, BUFFER_SIZE);
        QImage img(reinterpret_cast<uchar *>(m_buffer), IMAGE_WIDTH, IMAGE_HEIGHT, QImage::Format_ARGB32);
        auto wnd = window();
        if (wnd != nullptr)
            m_newTexture = wnd->createTextureFromImage(img);
    }
}

QString VideoRenderer::getSource(void)
{
    return QString::fromStdString(m_camera->iSource);
}

void VideoRenderer::setSource(QString source)
{
    if (source.toStdString() != m_camera->iSource) {
        m_camera->iSource = source.toStdString();
        emit sourceChanged(source);
    }
}

int VideoRenderer::getWaitKeyTimeout(void)
{
    if (m_camera) {
        return m_camera->iWaitKeyTimeout;
    }
    return 18;
}

void VideoRenderer::setWaitKeyTimeout(int timeout)
{
    if (m_camera) {
        if (timeout != m_camera->iWaitKeyTimeout) {
            m_camera->iWaitKeyTimeout = timeout;
            emit waitKeyTimeoutChanged(timeout);
        }
    }
}

QString VideoRenderer::getName(void)
{
    return QString::fromStdString(m_camera->iName);
}

void VideoRenderer::setName(QString name)
{
    if (name.toStdString() != m_camera->iName) {
        m_camera->iName = name.toStdString();
        emit nameChanged(name);
    }
}

double VideoRenderer::getScaleF(void)
{
    return m_scalef;
}

void VideoRenderer::setScaleF(double scalef)
{
    if (scalef != m_scalef) {
        m_scalef = scalef;
        emit scaleFChanged(scalef);
    }
}

int VideoRenderer::getPipeLineStages(void)
{
    if (m_camera) {
        return m_camera->iPipelineConfig[cvl::IDX_PIPELINE_STAGES];
    }
    return 0;
}

void VideoRenderer::setPipeLineStages(int stages)
{
    if (m_camera) {
        if (stages != m_camera->iPipelineConfig[cvl::IDX_PIPELINE_STAGES]) {
            m_camera->iPipelineConfig[cvl::IDX_PIPELINE_STAGES] = stages;
            emit pipelineStagesChanged(stages);
        }
    }
}

double VideoRenderer::getFaceConfidence()
{
    return (double)(m_camera->iPipelineConfig[cvl::IDX_FACE_CONFIDENCE]) / 10;
}

void VideoRenderer::setFaceConfidence(double confidence)
{
    if (confidence != m_camera->iPipelineConfig[cvl::IDX_FACE_CONFIDENCE]) {
        m_camera->iPipelineConfig[cvl::IDX_FACE_CONFIDENCE] = (int)(confidence * 10);
        emit faceConfidenceChanged(confidence);
    }
}

double VideoRenderer::getObjectConfidence()
{
    return (double)(m_camera->iPipelineConfig[cvl::IDX_OBJECT_CONFIDENCE]) / 10;
}

void VideoRenderer::setObjectConfidence(double confidence)
{
    if (confidence != m_camera->iPipelineConfig[cvl::IDX_OBJECT_CONFIDENCE]) {
        m_camera->iPipelineConfig[cvl::IDX_OBJECT_CONFIDENCE] = (int)(confidence * 10);
        emit objectConfidenceChanged(confidence);
    }
}

double VideoRenderer::getFacerecConfidence()
{
    return (double)(m_camera->iPipelineConfig[cvl::IDX_FACEREC_CONFIDENCE]) / 10;
}

void VideoRenderer::setFacerecConfidence(double confidence)
{
    if (confidence != m_camera->iPipelineConfig[cvl::IDX_FACEREC_CONFIDENCE]) {
        m_camera->iPipelineConfig[cvl::IDX_FACEREC_CONFIDENCE] = (int)(confidence * 10);
        emit facerecConfidenceChanged(confidence);
    }
}

int VideoRenderer::getAreaThreshold()
{
    return m_camera->iPipelineConfig[cvl::IDX_MOCAP_EXCLUDE_AREA];
}

void VideoRenderer::setAreaThreshold(int area)
{
    if (area != m_camera->iPipelineConfig[cvl::IDX_MOCAP_EXCLUDE_AREA]) {
        m_camera->iPipelineConfig[cvl::IDX_MOCAP_EXCLUDE_AREA] = area;
        emit areaThresholdChanged(area);
    }
}

int VideoRenderer::getBboxThickness()
{
    return m_camera->iPipelineConfig[cvl::IDX_BOUNDINGBOX_THICKNESS];
}

void VideoRenderer::setBboxThickness(int px)
{
    if (px != m_camera->iPipelineConfig[cvl::IDX_BOUNDINGBOX_THICKNESS]) {
        m_camera->iPipelineConfig[cvl::IDX_BOUNDINGBOX_THICKNESS] = px;
        emit areaThresholdChanged(px);
    }
}

int VideoRenderer::getMocapAlgo()
{
    return m_camera->iPipelineConfig[cvl::IDX_MOCAP_ALGO];
}

void VideoRenderer::setMocapAlgo(int algo)
{
    if (algo != m_camera->iPipelineConfig[cvl::IDX_MOCAP_ALGO]) {
        m_camera->iPipelineConfig[cvl::IDX_MOCAP_ALGO] = algo;
        emit mocapAlgoChanged(algo);
    }
}