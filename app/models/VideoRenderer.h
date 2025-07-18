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

class VideoRenderer : public QQuickItem {

    Q_OBJECT

    QML_ELEMENT

    public:

    VideoRenderer(QQuickItem *parent = nullptr);
    ~VideoRenderer();

    void componentComplete() override;
    QSGNode *updatePaintNode(QSGNode *node, UpdatePaintNodeData *) override;

    Q_INVOKABLE void stop();
    Q_INVOKABLE void start();
    Q_INVOKABLE void AddResultsForTraining(QString path, QString name, QString id);

    Q_PROPERTY(int flags READ getFlags WRITE setFlags NOTIFY flagsChanged);
    Q_PROPERTY(QVariantMap cfg READ getCfg WRITE setCfg NOTIFY cfgChanged);
    Q_PROPERTY(QString name READ getName WRITE setName NOTIFY nameChanged);
    Q_PROPERTY(int stages READ getStages WRITE setStages NOTIFY stagesChanged);
    Q_PROPERTY(double scalef READ getScaleF WRITE setScaleF NOTIFY scaleFChanged);
    Q_PROPERTY(QString source READ getSource WRITE setSource NOTIFY sourceChanged);
    Q_PROPERTY(QString chatids READ getChatids WRITE setChatids NOTIFY chatidsChanged);
    Q_PROPERTY(QString botToken READ getBotToken WRITE setBotToken NOTIFY botTokenChanged);
    Q_PROPERTY(int mocapAlgo READ getMocapAlgo WRITE setMocapAlgo NOTIFY mocapAlgoChanged);
    Q_PROPERTY(int skipFrames READ getSkipFrames WRITE setSkipFrames NOTIFY skipFramesChanged);
    Q_PROPERTY(int bboxThickness READ getBboxThickness WRITE setBboxThickness NOTIFY bboxThicknessChanged);
    Q_PROPERTY(int areaThreshold READ getAreaThreshold WRITE setAreaThreshold NOTIFY areaThresholdChanged);
    Q_PROPERTY(QString resultsFolder READ getResultsFolder WRITE setResultsFolder NOTIFY resultsFolderChanged);
    Q_PROPERTY(int waitKeyTimeout READ getWaitKeyTimeout WRITE setWaitKeyTimeout NOTIFY waitKeyTimeoutChanged);
    Q_PROPERTY(double faceConfidence READ getFaceConfidence WRITE setFaceConfidence NOTIFY faceConfidenceChanged);
    Q_PROPERTY(int bbSizeIncrement READ getBbSizeIncrement WRITE setBbSizeIncrement NOTIFY bbSizeIncrementChanged);
    Q_PROPERTY(double objectConfidence READ getObjectConfidence WRITE setObjectConfidence NOTIFY objectConfidenceChanged);
    Q_PROPERTY(double facerecConfidence READ getFacerecConfidence WRITE setFacerecConfidence NOTIFY facerecConfidenceChanged);

    public slots:

    int getFlags();
    int getMocapAlgo();
    int getSkipFrames();
    int getStages(void);
    QString getChatids();
    QVariantMap getCfg();
    QString getBotToken();
    QString getName(void);
    void setMocapAlgo(int);
    int getBboxThickness();
    double getScaleF(void);
    void setSkipFrames(int);
    QString getSource(void);
    void setChatids(QString);
    int getBbSizeIncrement();
    void setCfg(QVariantMap);
    void setFlags(int flags);
    void setBotToken(QString);
    void setBboxThickness(int);
    double getFaceConfidence();
    int getFacerecConfidence();
    QString getResultsFolder();
    int getAreaThreshold(void);
    int getWaitKeyTimeout(void);
    void setBbSizeIncrement(int);
    double getObjectConfidence();
    void setName(QString source);
    void setScaleF(double scalef);
    void setFaceConfidence(double);
    void setFacerecConfidence(int);
    void setResultsFolder(QString);
    void setSource(QString source);
    void setStages(int stageFlags);
    void setAreaThreshold(int area);
    void setObjectConfidence(double);
    void setWaitKeyTimeout(int source);

    signals:

    void flagsChanged(int);
    void stagesChanged(int);
    void nameChanged(QString);
    void mocapAlgoChanged(int);
    void scaleFChanged(double);
    void skipFramesChanged(int);
    void sourceChanged(QString);
    void chatidsChanged(QString);
    void cfgChanged(QVariantMap);
    void botTokenChanged(QString);
    void bboxThicknessChanged(int);
    void areaThresholdChanged(int);
    void waitKeyTimeoutChanged(int);
    void bbSizeIncrementChanged(int);
    void resultsFolderChanged(QString);
    void faceConfidenceChanged(double);
    void objectConfidenceChanged(double);
    void facerecConfidenceChanged(double);

    protected:

    void createStatic();
    void updateStatic();
    QImage MatToQImage(const cv::Mat& mat);
    void createImageFromMat(const cv::Mat& frame);
    void updateFrame(const cv::Mat& frame = cv::Mat());

    private:

    QTimer m_timer;
    QString chatids;
    QString botToken;
    QVariantMap m_cfg;
    cvl::SPCamera m_camera;
    QSGTexture *m_texture = nullptr;
    QSGTexture *m_newTexture = nullptr;
    uint32_t m_buffer[BUFFER_SIZE] = {};
};

#endif