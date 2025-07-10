[Download](https://github.com/n-mam/offset/releases/download/2.1/Offset-2.1.zip)

#### The following 3 tools are currently implemented

Block level backup tool
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

FTP(S) client<br/>
- Supports plain and secure FTPS (using openssl async bio).<br/>
- Ability to browse while transfers are in progress.<br/>
- Directory listing support for Linux, Windows and MLSD.<br/>
- FTPS supports TLS1.3<br/><br/>

Camera tool<br/>
- Face detection, Motion detection, Face recognition.<br/>
- Uses default opencv built-in models and DNN based detectors.<br/>
- Detection configurability on a per camera basis.<br/>
- Ability to save detection results on a per camera basis.<br/>
- The release has default(non-CUDA) opencv build for CPUs.<br/>
- For NVIDIA GPU it is recommended to do a custom opencv CUDA/CUDNN variant build via vcpkg.<br/>
- The code either ways supports both CUDA/CPU backend and target for DNN inference; in order.<br/>
- Set CVL_MODELS_ROOT env variable to the local MODELS folder from repo for detections to work.<br/>
- Define a new camera with face detection and specify a results folder. Run face detection for 5-10 secs and then stop. Then use the facerec "train" option to register the above face detection results with facerec. (via camera settings) <br/>
- The system can be tested by defining a "Window capture" source in OBS studio against youtube running inside the browser. Then expose the webbrowser feed over RTSP(using OBS RSTP server plugin). This can then be captured via a cam configuration in offset using the obs rtsp url for running detections.<br/>

#### vcpkg dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && bootstrap-vcpkg.bat
vcpkg.exe install openssl crc32c rapidjson zlib opencv4[contrib,core,dnn,ffmpeg,highgui,jpeg] --recurse
sudo apt-get install build-essential zip curl vim bison nasm meson pkg-config
./vcpkg install tinyxml2 libzip openssl crc32c rapidjson zlib opencv4[contrib,core,dnn,ffmpeg,highgui,jpeg] --recurse
use the resulting toolchain file in cmake configure step as highlited under the build section
```

#### QT-6.9.0 source build
```
make sure ninja and python3.9 are under PATH
set PATH=D:\Python39;%PATH%
where python
D:\Python39\python.exe
C:\Users\nmam\AppData\Local\Microsoft\WindowsApps\python.exe
where ninja
C:\Windows\System32\ninja.exe
C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe

\qt-everywhere-src-6.9.0\configure.bat -prefix D:\Qt-6.9.0\install -skip qtconnectivity -nomake examples -nomake tests -skip speech -skip scxml -skip qtsensors -skip qtserialbus -skip qtspeech -skip qtdoc -skip qtandroidextras -release

Qt is now configured for building. Just run 'cmake --build . --parallel'
Once everything is built, you must run 'cmake --install .'
Qt will be installed into 'D:/QT-6.8.2/install'
```

#### Build

```sh
git clone https://github.com/n-mam/offset.git
cd offset && mkdir build && cd build
SET Qt6_DIR=D:\QT-6.9.0\install\lib\cmake\Qt6
cmake -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release

Run as admin (elevation needed only for the block level backup tool):
SET PATH=D:\QT-6.9.0\install\bin;%PATH%
qml\Release\offset.exe
```

#### Deploy:

```sh
windeployqt --qmldir D:\offset\app\qml D:\offset\build\app\Release\offset.exe
```
vc redist is bundled with package zip; in case your system does not have that installed already

<p align="center">
 <img src="https://lh3.googleusercontent.com/d/193lB9OfdeZ-hfUxqmythLaAwk1ExGaEE" width="65%">
</p>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1L9AJ0i0d4H2kKGp-TRFpxCeYFjPgzDnW" width="70%">
</p>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1LiNTVr3Ps8EfEbSOOcoRaBLHk4ymfEf7" width="70%">
</p>
<p align="center">
 <img src="https://lh3.googleusercontent.com/d/1gClqVfeIM45I8YqFpaDt0jUphnuAlqP1" width="70%">
</p>

#### Contact:
Telegram: https://t.me/neelabhm