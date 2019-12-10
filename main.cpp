#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuick>
// Added for reMarkable support
#include <QtPlugin>
#ifdef __arm__
Q_IMPORT_PLUGIN(QsgEpaperPlugin)
#endif
// end reMarkable additions
#include "edit_utils.h"
#include <QtQml>

int main(int argc, char *argv[])
{
    //  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    // Added for reMarkable support
#ifdef __arm__
    qputenv("QMLSCENE_DEVICE", "epaper");
    qputenv("QT_QPA_PLATFORM", "epaper:enable_fonts");
    qputenv("QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS", "rotate=180");
    qputenv("QT_QPA_GENERIC_PLUGINS", "evdevtablet");
#endif
    // end reMarkable additions


    QString configDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    qDebug() << configDir ;

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    qmlRegisterType<EditUtils>("io.singleton", 1, 0, "EditUtils");

    engine.rootContext()->setContextProperty("screen", app.primaryScreen()->geometry());
    engine.rootContext()->setContextProperty("home_dir", configDir);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
