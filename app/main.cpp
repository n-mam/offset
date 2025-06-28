#include <QFont>
#include <QIcon>
#include <QtGlobal>
#include <QQmlContext>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <Logger.h>
#include <AppConfig.h>
#include <osl/singleton>
#include <LocalFsModel.h>
#include <RemoteFsModel.h>
#include <VideoRenderer.h>
#include <CompareManager.h>
#include <CompareFileModel.h>

#ifdef _WIN32
#include <DiskListModel.h>
#include <Windows.h>
#endif

void q_logger(QtMsgType, const QMessageLogContext&, const QString&);

int main(int argc, char *argv[])
{
    qputenv("QSG_RENDER_LOOP", "threaded");

    #if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    #endif

    qInstallMessageHandler(q_logger);

    if (qgetenv("CVL_MODELS_ROOT").isEmpty()) {
        qputenv("CVL_MODELS_ROOT", "D:/offset/cvl/MODELS/");
    }
    if (qgetenv("QT_QUICK_CONTROLS_STYLE").isEmpty()) {
        qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Material"));
    }
    if (qgetenv("QT_QUICK_CONTROLS_MATERIAL_THEME").isEmpty()) {
        qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("Dark"));
    }

    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(":app.ico"));

    QFont font("Consolas", 10);
    app.setFont(font);

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

    engine.rootContext()->setContextProperty("appConfig", new AppConfig());

    qmlRegisterType<VideoRenderer>("CustomElements", 1, 0, "VideoRenderer");
    qmlRegisterType<CompareFileModel>("CustomElements", 1, 0, "CompareFileModel");

    engine.rootContext()->setContextProperty("logger", new Logger());
    engine.rootContext()->setContextProperty("localFsModel", getInstance<LocalFsModel>());
    engine.rootContext()->setContextProperty("remoteFsModel", getInstance<RemoteFsModel>());
    engine.rootContext()->setContextProperty("compareManager", getInstance<CompareManager>());
    engine.rootContext()->setContextProperty("transferManager", getInstance<TransferManager>());
    #ifdef _WIN32
    engine.rootContext()->setContextProperty("diskListModel", new DiskListModel());
    #endif

    engine.load(url);
    return app.exec();
}

void q_logger(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    char buffer[2048];
    QByteArray localMsg = msg.toLocal8Bit();

    switch (type) {
        case QtDebugMsg:
        sprintf(buffer, "q_logger: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
        break;
        case QtInfoMsg:
        sprintf(buffer, "q_logger Info: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
        break;
        case QtWarningMsg:
        sprintf(buffer, "q_logger Warning: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
        break;
        case QtCriticalMsg:
        sprintf(buffer, "q_logger Critical: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
        break;
        case QtFatalMsg:
        sprintf(buffer, "q_logger Fatal: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
        #ifdef _WIN32
        //OutputDebugStringA(buffer);
        #endif
        abort();
    }
    qDebug() << buffer;
    LOG << buffer;
}