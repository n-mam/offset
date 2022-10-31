cmake_minimum_required(VERSION 3.0)

project(offset)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(OpenSSL REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)
find_package(Crc32c CONFIG REQUIRED)

add_executable(offset offset.cpp)

set_property(TARGET offset PROPERTY CXX_STANDARD 17)

target_include_directories(
  offset
  PRIVATE
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_SOURCE_DIR}/src/osl
  ${CMAKE_SOURCE_DIR}/src/npl
  ${CMAKE_SOURCE_DIR}/src/fxc
)

target_link_libraries(
  offset
  rapidjson
  OpenSSL::SSL
  OpenSSL::Crypto
  Crc32c::crc32c
)

if (WIN32)
target_link_libraries(offset Ws2_32.lib VssApi.lib)
endif(WIN32)