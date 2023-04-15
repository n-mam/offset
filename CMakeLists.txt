cmake_minimum_required(VERSION 3.0)

project(offset)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(ZLIB REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)
find_package(Crc32c CONFIG REQUIRED)
find_package(Qt6 COMPONENTS Quick QuickControls2 Gui QUIET)

include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/osl
  ${CMAKE_SOURCE_DIR}/npl
  ${CMAKE_SOURCE_DIR}/fxc
)

if(MSVC)
  add_definitions(
    -D_CRT_SECURE_NO_WARNINGS 
    -D_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
endif()

if(Qt6_FOUND)
  add_subdirectory(qml)
endif()

add_executable(Test test.cpp)

set_property(TARGET Test PROPERTY CXX_STANDARD 17)

target_link_libraries(
  Test
  PRIVATE
  rapidjson
  ZLIB::ZLIB
  OpenSSL::SSL
  OpenSSL::Crypto
  Crc32c::crc32c
)

if (WIN32)
  target_link_libraries(Test PRIVATE Ws2_32.lib VssApi.lib)
endif(WIN32)