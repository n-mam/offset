#include <VideoRenderer.h>

#include <QMutexLocker>
#include <QRandomGenerator>
#include <QSGSimpleRectNode>
#include <QSGSimpleTextureNode>

VideoRenderer::VideoRenderer(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(QQuickItem::ItemHasContents, true);
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
    if (m_camera)
        m_camera->stop();
}

void VideoRenderer::start(QVariant stages)
{
    std::vector<std::string> s;
    for (const auto& stage : stages.toList())
        s.push_back(stage.toString().toStdString());

    if (!m_source.isEmpty()) {
        m_camera = std::make_shared<cvl::camera>(m_source.toStdString());
        m_camera->start(s,
            [this](const cv::Mat& frame){
                QMetaObject::invokeMethod(this,
                    [this, f = frame.clone()](){
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
        node->setRect(boundingRect());
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
    return m_source;
}

void VideoRenderer::setSource(QString source)
{
    if (source != m_source) {
        m_source = source;
    }
}
