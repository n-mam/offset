### offset

C++ base components library

#### Dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg.exe install openssl:x64-windows crc32c:x64-windows rapidjson:x64-windows zlib:x64-windows
vcpkg.exe integrate install
QT6 can be installed via vcpkg also in which case the supplied vcpkg.cmake toolchain during cmake configure should pick QT6 dependencies as well. I typically use full source builds for QT
```

### QT-6.4.0 build

```
Download and extract QT-6.4.0 src tar ball under say D:\
Download ninja and jom under D:\

SET PATH=%PATH%;D:\QT-6.4.0\ninja-win;D:\QT-6.4.0\jom_1_1_3;D:\Python39

Adapt paths in the above SET command accordingly

..\qt-everywhere-src-6.4.0\configure.bat -prefix D:\QT-6.4.0\INSTALL -opensource -platform win32-msvc -skip qtconnectivity -nomake examples -nomake tests -skip speech -skip scxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtdoc -skip qtandroidextras -release

Qt is now configured for building. Just run 'cmake --build . --parallel'

Once everything is built, you must run 'cmake --install .'
Qt will be installed into 'D:/QT-6.4.0/INSTALL'
```

#### Build

```sh
git clone https://github.com/n-mam/cpp-npl.git
cd cpp-npl
mkdir build
cd build
SET PATH=%PATH%;D:\QT-6.4.0\INSTALL\bin
cmake -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Debug
Run : qml\Debug\offset.exe
Deploy: windeployqt --qmldir E:\offset\qml E:\offset\build\qml\Debug\offset.exe
```