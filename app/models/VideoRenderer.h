#ifndef VIDEORENDERER_H
#define VIDEORENDERER_H

#include <QImage>
#include <QTimer>
#include <QSGTexture>
#include <QQuickItem>

#include <cam/camera>

#define IMAGE_WIDTH (100)
#define IMAGE_HEIGHT (100)
#define BUFFER_SIZE (IMAGE_WIDTH * IMAGE_HEIGHT)

class VideoRenderer : public QQuickItem
{
  Q_OBJECT
  QML_ELEMENT

  public:

  VideoRenderer(QQuickItem *parent = nullptr);
  ~VideoRenderer();

  QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;
  void componentComplete() override;

  Q_PROPERTY(QString source READ getSource WRITE setSource);
  
  public slots:

  QString getSource(void);
  void setSource(QString source);

  protected:

  void createImage();
  void updateFrame();

  private:

  QString m_source;

  SPCamera m_camera;

  uint32_t m_buffer[BUFFER_SIZE] = {};

  QSGTexture *m_texture = nullptr;

  QSGTexture *m_newTexture = nullptr;
};

#endif