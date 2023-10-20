#ifndef VIDEORENDERER_H
#define VIDEORENDERER_H

#include <QImage>
#include <QTimer>
#include <QSGTexture>
#include <QQuickItem>

#include <cvl/cvl>

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

  Q_INVOKABLE void start(QVariant stages);
  Q_INVOKABLE void stop(void);

  Q_PROPERTY(QString source READ getSource WRITE setSource);
  Q_PROPERTY(int waitKeyTimeout READ getWaitKeyTimeout WRITE setWaitKeyTimeout);
  Q_PROPERTY(int pipelineStages READ getPipeLineStages WRITE setPipeLineStages);

  public slots:

  QString getSource(void);
  void setSource(QString source);
  int getWaitKeyTimeout(void);
  void setWaitKeyTimeout(int source);
  int getPipeLineStages(void);
  void setPipeLineStages(int stageFlags);

  protected:

  void createStatic();
  void updateStatic();
  void updateFrame(const cv::Mat& frame = cv::Mat());
  void createImageFromMat(const cv::Mat& frame);
  QImage MatToQImage(const cv::Mat& mat);

  private:

  QTimer m_timer;

  QString m_source;

  cvl::SPCamera m_camera;

  uint32_t m_buffer[BUFFER_SIZE] = {};

  QSGTexture *m_texture = nullptr;

  QSGTexture *m_newTexture = nullptr;
};

#endif