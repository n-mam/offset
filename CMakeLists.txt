cmake_minimum_required(VERSION 3.0)

project(offset)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(ZLIB REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)
find_package(Crc32c CONFIG REQUIRED)

include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/osl
  ${CMAKE_SOURCE_DIR}/npl
  ${CMAKE_SOURCE_DIR}/fxc
)

add_subdirectory(app)

add_executable(Test test.cpp)

set_property(TARGET Test PROPERTY CXX_STANDARD 17)

target_link_libraries(
  Test
  rapidjson
  ZLIB::ZLIB
  OpenSSL::SSL
  OpenSSL::Crypto
  Crc32c::crc32c
)

if (WIN32)
  target_link_libraries(Test Ws2_32.lib VssApi.lib)
endif(WIN32)