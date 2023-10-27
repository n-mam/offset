[Download](https://github.com/n-mam/offset/releases/download/2.1/Offset-2.1.zip)

#### The following 3 tools are currently implemented

FXC
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/193lB9OfdeZ-hfUxqmythLaAwk1ExGaEE" width="65%">
</p>
- Requires elevation. Please run as admin.<br/>
- Creates volume level images using either VSS snapshots or from live volume.<br/>
- Creates volume level images of already existing persistent VSS snapshots on the system.<br/>
- Ability to exclude files (only for VSS backups) by deleting them from the source snapshot.<br/>
- Support for MBR and GPT partitions. Volumes > 2TB are by default saved as VHDX with GPT partitioning.<br/>
- Supported virtual disk formats :<br/>
  - Dynamic vhd (d-vhd)<br/>
  - Fixed vhd (f-vhd)<br/>
  - Dynamic vhdx (d-vhdx)<br/>
  - Raw volume image (raw)<br/>
- Volume images can either be generated locally or streamed to an FTP server.<br/>
- URI format for streaming to FTP:<br/>
  - ftps://username:password@hostname:port/a/b/c<br/><br/>

FTPS<br/>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1L9AJ0i0d4H2kKGp-TRFpxCeYFjPgzDnW" width="70%">
</p>
- Supports plain and secure FTPS (using openssl async bio).<br/>
- Ability to browse while transfers are in progress.<br/>
- Directory listing support for Linux, Windows and MLSD.<br/>
- FTPS supports TLS1.3<br/><br/>

CAMERA<br/>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1LiNTVr3Ps8EfEbSOOcoRaBLHk4ymfEf7" width="70%">
</p>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1gClqVfeIM45I8YqFpaDt0jUphnuAlqP1" width="70%">
</p>
- Face detection, Motion detection, Face recognition.<br/>
- Uses default opencv built-in models and DNN based detectors.<br/>
- Detection configurability on a per camera basis.<br/>
- Ability to save detection results on a per camera basis.<br/>
- The release has default(non-CUDA) opencv build for CPUs.<br/>
- For NVIDIA GPU it is recommended to do a custom opencv CUDA/CUDNN variant build via vcpkg.<br/>
- The code either ways supports both CUDA/CPU backend and target for DNN inference; in order.<br/>

#### vcpkg dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat

vcpkg.exe install openssl:x64-windows crc32c:x64-windows rapidjson:x64-windows zlib:x64-windows opencv4[contrib,core,default-features,dnn,ffmpeg]:x64-windows --recurse

sudo apt-get install build-essential zip curl vim bison meson pkg-config

./vcpkg install openssl:x64-linux crc32c:x64-linux rapidjson:x64-linux zlib:x64-linux opencv4[contrib,core,default-features,dnn,ffmpeg]:x64-linux --recurse

vcpkg.exe integrate install

use the resulting toolchain file in cmake configure step as highlited under the build section
```

#### qt-6.5.3 source build

```
make sure ninja and python3.9 are under PATH

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
cd offset && mkdir build && cd build
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
windeployqt --qmldir D:\offset\app\qml D:\offset\build\app\Release\offset.exe
```
vc redist is bundled with package zip; in case your system does not have that installed already

#### Contact:
Telegram: https://t.me/neelabhm