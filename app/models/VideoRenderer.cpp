#include <VideoRenderer.h>

#include <QSGSimpleRectNode>
#include <QRandomGenerator>
#include <QSGSimpleTextureNode>
#include <QMutexLocker>

VideoRenderer::VideoRenderer(QQuickItem *parent): QQuickItem(parent)
{
  setFlag(QQuickItem::ItemHasContents, true);
  QTimer *timer = new QTimer(this);
  connect(timer, &QTimer::timeout, this, &VideoRenderer::updateFrame);
  timer->start(100);
}

VideoRenderer::~VideoRenderer()
{
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
  m_camera = std::make_shared<camera>(m_source.toStdString());
  m_camera->start();
  QQuickItem::componentComplete();
}

QSGNode *VideoRenderer::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
  auto node = static_cast<QSGSimpleTextureNode *>(oldNode);

  if (!node) {
    if (m_newTexture != nullptr) {
      node = new QSGSimpleTextureNode();
      node->setRect(boundingRect());
    }
  }

  if (node) {
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

void VideoRenderer::createImage()
{
  if (m_newTexture == nullptr) {
    QRandomGenerator::global()->fillRange(m_buffer, BUFFER_SIZE);
    QImage img(reinterpret_cast<uchar *>(m_buffer), IMAGE_WIDTH, IMAGE_HEIGHT, QImage::Format_ARGB32);
    auto wnd = window();
    if (wnd != nullptr)
      m_newTexture = wnd->createTextureFromImage(img);
  }
}

void VideoRenderer::updateFrame()
{
  createImage();
  update();
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
