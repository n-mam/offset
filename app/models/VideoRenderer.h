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

  Q_INVOKABLE void stop();
  Q_INVOKABLE void start();

  Q_PROPERTY(double scaleF READ getScaleF WRITE setScaleF NOTIFY scaleFChanged);
  Q_PROPERTY(QString name READ getName WRITE setName NOTIFY nameChanged);
  Q_PROPERTY(QString source READ getSource WRITE setSource NOTIFY sourceChanged);
  Q_PROPERTY(int waitKeyTimeout READ getWaitKeyTimeout WRITE setWaitKeyTimeout NOTIFY waitKeyTimeoutChanged);
  Q_PROPERTY(int pipelineStages READ getPipeLineStages WRITE setPipeLineStages NOTIFY pipelineStagesChanged);

  public slots:

  double getScaleF(void);
  void setScaleF(double scalef);
  QString getSource(void);
  void setSource(QString source);
  QString getName(void);
  void setName(QString source);
  int getWaitKeyTimeout(void);
  void setWaitKeyTimeout(int source);
  int getPipeLineStages(void);
  void setPipeLineStages(int stageFlags);

  signals:

  void nameChanged(QString);
  void sourceChanged(QString);
  void scaleFChanged(double);
  void waitKeyTimeoutChanged(int);
  void pipelineStagesChanged(int);

  protected:

  void createStatic();
  void updateStatic();
  void updateFrame(const cv::Mat& frame = cv::Mat());
  void createImageFromMat(const cv::Mat& frame);
  QImage MatToQImage(const cv::Mat& mat);

  private:

  double m_scalef = 0.6;

  QTimer m_timer;

  QString m_source;

  cvl::SPCamera m_camera;

  uint32_t m_buffer[BUFFER_SIZE] = {};

  QSGTexture *m_texture = nullptr;

  QSGTexture *m_newTexture = nullptr;
};

#endif