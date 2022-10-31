#include <QFont>
#include <QQmlContext>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <DiskListModel.h>

int main(int argc, char *argv[])
{
  qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Material"));
  qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("Dark"));

  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  const QUrl url(u"qrc:/main.qml"_qs);

  QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                      &app, [url](QObject *obj, const QUrl &objUrl) {
      if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
  }, Qt::QueuedConnection);

  engine.rootContext()->setContextProperty("diskListModel", new DiskListModel());

  engine.load(url);

  QFont font("Consolas", 11);
  app.setFont(font);

  return app.exec();
}
