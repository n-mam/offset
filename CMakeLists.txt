cmake_minimum_required(VERSION 2.8...3.13)

project(offset)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(CURL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Crc32c CONFIG REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Gui)

include_directories(
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/osl
    ${CMAKE_SOURCE_DIR}/npl
    ${CMAKE_SOURCE_DIR}/fxc
    ${CMAKE_SOURCE_DIR}/cvl
)

if(MSVC)
    add_definitions(
        -D_CRT_SECURE_NO_WARNINGS
        -D_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
endif()

add_subdirectory(app)

add_executable(Test test.cpp)

set_property(TARGET Test PROPERTY CXX_STANDARD 20)

target_link_libraries(
    Test
    PRIVATE
    rapidjson
    opencv_ml
    ZLIB::ZLIB
    opencv_dnn
    opencv_dpm
    opencv_hdf
    opencv_face
    opencv_core
    OpenSSL::SSL
    opencv_aruco
    opencv_bgsegm
    CURL::libcurl
    Crc32c::crc32c
    opencv_tracking
    OpenSSL::Crypto
)

if (WIN32)
    SET (CMAKE_CXX_FLAGS_RELEASE "/Zi /Od")
    SET_TARGET_PROPERTIES(
        Test PROPERTIES LINK_FLAGS
        "/DEBUG /OPT:REF")
endif (WIN32)

if (WIN32)
  target_link_libraries(Test PRIVATE Ws2_32.lib VssApi.lib)
endif(WIN32)