[Download](https://github.com/n-mam/offset/releases/download/2.0/offset-2.0.zip)
<p align="center">
 <img src="https://drive.google.com/uc?id=1u-tsnDwuQPH6OXepCAEoARDSgAWCqNT2" width="45%">
 <img src="https://drive.google.com/uc?id=1RpPvy074uBcxyvaE7RI3M91AXgtzr1Qz" width="45%">
</p>

#### Features

FXC

- Requires elevation. Please run as admin.
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

FTPS

- Supports plain and secure FTPS (using openssl async bio).
- Ability to browse while transfers are in progress.
- Directory listing support for Linux, Windows and MLSD.
- FTPS supports TLS1.3

#### vcpkg dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg.exe install openssl:x64-windows crc32c:x64-windows rapidjson:x64-windows zlib:x64-windows opencv[contrib]:x64-windows
./vcpkg install openssl:x64-linux crc32c:x64-linux rapidjson:x64-linux zlib:x64-linux opencv[contrib]:x64-linux
vcpkg.exe integrate install

use the resulting toolchain file in cmake configure step as highlited under the build section
```

#### qt-6.5.3 source build

```
make sure ninja nd python3.9 are under PATH

C:\>set PATH=D:\Python39;%PATH%

C:\>where python
D:\Python39\python.exe
C:\Users\nmam\AppData\Local\Microsoft\WindowsApps\python.exe

C:\>where ninja
C:\Windows\System32\ninja.exe
C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe

\qt-everywhere-src-6.5.3\configure.bat -prefix D:\qt-6.5.3\install -skip qtconnectivity -nomake examples -nomake tests -skip speech -skip scxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtdoc -skip qtandroidextras -release

Qt is now configured for building. Just run 'cmake --build . --parallel'
Once everything is built, you must run 'cmake --install .'
Qt will be installed into 'D:/qt-6.5.3/install'
```

#### Build

```sh
git clone https://github.com/n-mam/offset.git
cd offset
mkdir build
cd build
SET Qt6_DIR=D:\qt-6.5.3\install
cmake -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release

Run as admin (needed for FXC):
SET PATH=%PATH%;D:\qt-6.5.3\install\bin
qml\Release\offset.exe
```

#### Deploy:

```sh
windeployqt --qmldir E:\offset\qml E:\offset\build\qml\Release\offset.exe
```
vc redist is bundled with package zip; in case your system does not have that installed already

#### Contact:
Telegram: https://t.me/neelabhm