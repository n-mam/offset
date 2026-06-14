[Download (Windows-x64)](https://github.com/n-mam/offset/releases/download/2.1/Offset-2.1.zip)

#### The following 6 tools are currently implemented

- FTPS client<br/>
- Camera tool<br/>
- 2D Floor planner tool<br/>
- Point cloud visualizer<br/>
- Block level backup tool<br/>
- File diff tool (LCS based)<br/>
- MCU tool (companion app for mcu repo)<br/>

#### vcpkg dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && bootstrap-vcpkg.bat
vcpkg.exe install tinyxml2 libzip openssl curl crc32c rapidjson pdal qhull zlib cJSON boost flann nanoflann opencv4[contrib,core,dnn,ffmpeg,highgui,jpeg,hdf] --recurse
sudo apt-get install build-essential zip curl vim bison nasm meson pkg-config
./vcpkg install tinyxml2 libzip openssl crc32c rapidjson pdal qhull zlib cJSON boost flann nanoflann opencv4[contrib,core,dnn,ffmpeg,highgui,jpeg,hdf] --recurse
use the resulting toolchain file in cmake configure step as highlited under the build section
```

#### Qt-6.9.0 build
```
make sure ninja and python3.9 are under PATH
SET PATH=D:\Python39;%PATH%
where python
D:\Python39\python.exe
C:\Users\nmam\AppData\Local\Microsoft\WindowsApps\python.exe
where ninja
C:\Windows\System32\ninja.exe
C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe

\qt-everywhere-src-6.9.0\configure.bat -prefix D:\Qt-6.9.0\install -skip qtconnectivity -nomake examples -nomake tests -skip speech -skip scxml -skip qtsensors -skip qtserialbus -skip qtspeech -skip qtdoc -skip qtandroidextras -release

Qt is now configured for building. Just run 'cmake --build . --parallel'
Once everything is built, you must run 'cmake --install .'
Qt will be installed into 'D:/QT-6.9.0/install'
```

#### VTK[Qt] build
```
SET QT_DIR=D:\QT-6.9.0\install\lib\cmake\Qt6
SET Qt6_DIR=D:\QT-6.9.0\install\lib\cmake\Qt6
export QT_DIR=/home/nmam/Qt/6.9.1/gcc_64/lib/cmake/Qt6
cmake -GNinja -DVTK_BUILD_EXAMPLES=ON -DVTK_GROUP_ENABLE_Qt=YES -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release
NOTE: build(relese/debug) type of qt and vtk should match
```

#### PCL build
```
SET Qt6_DIR=D:\QT-6.9.0\install\lib\cmake\Qt6
SET VTK_DIR=d:\vtk\build\lib\cmake\vtk-9.6
cmake -DCMAKE_INSTALL_PREFIX=D:/pcl/install -DBUILD_visualization=ON -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release ..
cmake -DCMAKE_INSTALL_PREFIX=/home/nmam/code/pcl/install -DBUILD_visualization=ON -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release --parallel 4
```

#### App build
```sh
git clone https://github.com/n-mam/offset.git
cd offset && mkdir build && cd build
SET Qt6_DIR=D:\QT-6.9.0\install\lib\cmake\Qt6
export Qt6_DIR=/home/nmam/Qt/6.9.1/gcc_64/lib/cmake/Qt6
SET VTK_DIR=D:\vtk\build\lib\cmake\vtk-9.6
export VTK_DIR=/home/nmam/code/vtk/build/lib/cmake/vtk-9.6
set PCL_DIR=D:\pcl\install\cmake
export PCL_DIR=/home/nmam/code/pcl/install/share/pcl-1.15
cmake -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release

Run as admin (elevation needed only for the block level backup tool):
SET PATH=D:\QT-6.9.0\install\bin;D:\vtk\build\bin;%PATH%
SET CVL_MODELS_ROOT=E:\offset\cvl\MODELS\ (only for camera app)
qml\Release\offset.exe
```

#### Deploy:

```sh
windeployqt --qmldir E:\offset\app\qml E:\offset\build\app\Release\offset.exe
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