### cpp-npl

C++ base offset components library

#### Dependencies

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg.exe install openssl:x64-windows crc32c:x64-windows rapidjson:x64-windows
```

#### Build

```sh
git clone https://github.com/n-mam/cpp-npl.git
cd cpp-npl
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Debug
```
