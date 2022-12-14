[Download](https://github.com/n-mam/offset/releases/download/1.7/Offset-1.7.zip)
<p align="center">
 <img src="https://drive.google.com/uc?id=1u-tsnDwuQPH6OXepCAEoARDSgAWCqNT2" width="45%">
 <img src="https://drive.google.com/uc?id=1RpPvy074uBcxyvaE7RI3M91AXgtzr1Qz" width="45%">
</p>

> This is a work in progress. If anything stated below does not seem to be working with either the current master build or the last release please feel free to highlight that via issues. 

#### Features (FXC)

- Creates volume level images using either VSS snapshots or from live volume.
- Creates volume level images of already existing persistent VSS snapshots on the system.
- Ability to exclude files (only for VSS backups) by deleting them from the source snapshot.
- Support for MBR and GPT partitions. Volumes > 2TB are by default saved as VHDX with GPT partitioning.
- Supported virtual disk formats :
  - Dynamic vhd (d-vhd)
  - Fixed vhd (f-vhd)
  - Dynamic vhdx (d-vhdx)
  - Raw volume image (raw)
- Volume images can either be generated locally or streamed to an FTP server.
- URI format for streaming to FTP:
  - ftps://username:password@hostname:port/a/b/c

#### Features (FTPS)

- Supports plain and secure FTPS (using openssl async bio).
- Ability to browse while transfers are in progress.
- Directory listing support for Linux, Windows and MLSD.
- FTPS supports TLS1.3

#### Dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg.exe install openssl:x64-windows crc32c:x64-windows rapidjson:x64-windows zlib:x64-windows qt5[essentials]
vcpkg.exe integrate install

use the resulting toolchain file in cmake configure step as highlited under the build section

qt-6.4.0 source uild

In case you have pre-built QT or source builds, you can skip installing QT via vcpkg. 
Here are the steps for building QT6 from source:
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
git clone https://github.com/n-mam/offset.git
cd offset
mkdir build
cd build
SET PATH=%PATH%;D:\QT-6.4.0\INSTALL\bin
cmake -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release

Run as admin (needed for FXC):
qml\Release\offset.exe
```

#### Deploy:

```sh
windeployqt --qmldir E:\offset\qml E:\offset\build\qml\Release\offset.exe
```
vc redist is bundled with package zip; in case your system does not have that installed already

#### Contact:
Telegram: https://t.me/neelabhm