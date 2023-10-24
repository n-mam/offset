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

  void componentComplete() override;
  QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;

  Q_INVOKABLE void stop();
  Q_INVOKABLE void start();

  Q_PROPERTY(QVariantMap cfg READ getCfg WRITE setCfg NOTIFY cfgChanged);
  Q_PROPERTY(QString name READ getName WRITE setName NOTIFY nameChanged);
  Q_PROPERTY(double scalef READ getScaleF WRITE setScaleF NOTIFY scaleFChanged);
  Q_PROPERTY(QString source READ getSource WRITE setSource NOTIFY sourceChanged);
  Q_PROPERTY(int mocapAlgo READ getMocapAlgo WRITE setMocapAlgo NOTIFY mocapAlgoChanged);
  Q_PROPERTY(int bboxThickness READ getBboxThickness WRITE setBboxThickness NOTIFY bboxThicknessChanged);
  Q_PROPERTY(int areaThreshold READ getAreaThreshold WRITE setAreaThreshold NOTIFY areaThresholdChanged);
  Q_PROPERTY(double faceConfidence READ getFaceConfidence WRITE setFaceConfidence NOTIFY faceConfidenceChanged);
  Q_PROPERTY(double objectConfidence READ getObjectConfidence WRITE setObjectConfidence NOTIFY objectConfidenceChanged);
  Q_PROPERTY(double facerecConfidence READ getFacerecConfidence WRITE setFacerecConfidence NOTIFY facerecConfidenceChanged);
  Q_PROPERTY(int waitKeyTimeout READ getWaitKeyTimeout WRITE setWaitKeyTimeout NOTIFY waitKeyTimeoutChanged);
  Q_PROPERTY(int stages READ getStages WRITE setStages NOTIFY stagesChanged);

  public slots:

  QVariantMap getCfg();
  void setCfg(QVariantMap);
  int getMocapAlgo();
  void setMocapAlgo(int);
  int getBboxThickness();
  void setBboxThickness(int);
  double getFaceConfidence();
  void setFaceConfidence(double);
  double getObjectConfidence();
  void setObjectConfidence(double);
  double getFacerecConfidence();
  void setFacerecConfidence(double);
  double getScaleF(void);
  void setScaleF(double scalef);
  QString getSource(void);
  void setSource(QString source);
  QString getName(void);
  void setName(QString source);
  int getWaitKeyTimeout(void);
  void setWaitKeyTimeout(int source);
  int getStages(void);
  void setStages(int stageFlags);
  int getAreaThreshold(void);
  void setAreaThreshold(int area);

  signals:

  void cfgChanged(QVariantMap);
  void mocapAlgoChanged(int);
  void bboxThicknessChanged(int);
  void areaThresholdChanged(int);
  void faceConfidenceChanged(double);
  void objectConfidenceChanged(double);
  void facerecConfidenceChanged(double);
  void nameChanged(QString);
  void sourceChanged(QString);
  void scaleFChanged(double);
  void waitKeyTimeoutChanged(int);
  void stagesChanged(int);

  protected:

  void createStatic();
  void updateStatic();
  void updateFrame(const cv::Mat& frame = cv::Mat());
  void createImageFromMat(const cv::Mat& frame);
  QImage MatToQImage(const cv::Mat& mat);

  private:

  QVariantMap m_cfg;

  QTimer m_timer;

  double m_scalef = 0.6;

  cvl::SPCamera m_camera;

  uint32_t m_buffer[BUFFER_SIZE] = {};

  QSGTexture *m_texture = nullptr;

  QSGTexture *m_newTexture = nullptr;
};

#endif