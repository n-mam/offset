#include <QFont>
#include <QIcon>
#include <QQmlContext>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <Logger.h>
#include <LocalFsModel.h>
#include <RemoteFsModel.h>
#include <DiskListModel.h>

#include <Windows.h>

void q_logger(QtMsgType, const QMessageLogContext&, const QString&);

int main(int argc, char *argv[])
{
  qInstallMessageHandler(q_logger);

  qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Material"));
  qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("Dark"));

  QGuiApplication app(argc, argv);

  app.setWindowIcon(QIcon(":app.ico"));

  QFont font("Consolas", 10);
  app.setFont(font);
  
  QQmlApplicationEngine engine;

  const QUrl url(u"qrc:/main.qml"_qs);

  QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                      &app, [url](QObject *obj, const QUrl &objUrl) {
      if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
  }, Qt::QueuedConnection);

  engine.rootContext()->setContextProperty("logger", new Logger());
  engine.rootContext()->setContextProperty("diskListModel", new DiskListModel());
  engine.rootContext()->setContextProperty("fsModel", LocalFsModel::getInstance());
  engine.rootContext()->setContextProperty("ftpModel", RemoteFsModel::getInstance());
  engine.rootContext()->setContextProperty("transferManager", TransferManager::getInstance());

  engine.load(url);

  return app.exec();
}

void q_logger(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
  char buffer[2048];
  QByteArray localMsg = msg.toLocal8Bit();
  switch (type)
  {
    case QtDebugMsg:
      sprintf_s(buffer, "q_logger: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
      break;
    case QtInfoMsg:
      sprintf_s(buffer, "q_logger Info: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
      break;
    case QtWarningMsg:
      sprintf_s(buffer, "q_logger Warning: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
      break;
    case QtCriticalMsg:
      sprintf_s(buffer, "q_logger Critical: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
      break;
    case QtFatalMsg:
      sprintf_s(buffer, "q_logger Fatal: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
      //OutputDebugStringA(buffer);
      abort();
  }
  OutputDebugStringA(buffer);
  LOG << buffer;
}