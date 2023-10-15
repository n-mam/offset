set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(ZLIB REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Gui)

qt6_add_resources(QT_RESOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/qml/qml.qrc
  ${CMAKE_CURRENT_SOURCE_DIR}/assets/assets.qrc
)

add_executable(offset WIN32 ${QT_RESOURCES})

target_sources(offset PRIVATE main.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/Logger.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/FsModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/LocalFsModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/RemoteFsModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/BaseModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/TransferManager.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/VideoRenderer.cpp
)

if(WIN32)
  target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/assets/resource.rc)
  target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models/DiskListModel.cpp)
endif(WIN32)

set_property(TARGET offset PROPERTY CXX_STANDARD 17)

target_include_directories(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models)

target_link_libraries(
  offset
  PRIVATE
  Qt6::Gui
  Qt6::Quick
  Qt6::QuickControls2
  rapidjson
  ZLIB::ZLIB
  OpenSSL::SSL
  opencv_ml opencv_dnn opencv_dpm opencv_hdf opencv_face
  Crc32c::crc32c
  OpenSSL::Crypto
)

if(WIN32)
  target_link_libraries(offset PRIVATE Ws2_32.lib VssApi.lib)
endif(WIN32)

if (WIN32)
  SET (CMAKE_CXX_FLAGS_RELEASE "/Zi /Od")
  SET_TARGET_PROPERTIES(
   offset PROPERTIES
   LINK_FLAGS
   "/DEBUG /OPT:REF /OPT:ICF")
endif (WIN32)

#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DQT_QML_DEBUG")

#SET_TARGET_PROPERTIES(
#  offset
#  PROPERTIES
#  LINK_FLAGS
#  "/MANIFESTUAC:\"level='requireAdministrator' uiAccess='false'\" /SUBSYSTEM:WINDOWS"
#)