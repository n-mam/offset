### Qt 6.4 TreeView runner

####  Qt 6.4 build
```
set PATH=%PATH%;D:\QT-6.4.0\ninja-win;D:\QT-6.4.0\jom_1_1_3;D:\Python39

..\qt-everywhere-src-6.4.0\configure.bat -prefix D:\QT-6.4.0\INSTALL -opensource -platform win32-msvc -skip qtconnectivity -nomake examples -nomake tests -skip speech -skip scxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtdoc -skip qtandroidextras

Qt is now configured for building. Just run 'cmake --build . --parallel'

Once everything is built, you must run 'cmake --install .'
Qt will be installed into 'D:/QT-6.4.0/INSTALL'

To configure and build other Qt modules, you can use the following convenience script:
        D:/QT-6.4.0/INSTALL/bin/qt-configure-module.bat
```

#### Build
```
set PATh=%PATH%;D:\path\to\qt-6.4.0\INSTALL\bin
md build
cd build
cmake ..
cmake --build . --config Debug
```