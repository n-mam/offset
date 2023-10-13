set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

#SET(CMAKE_VERBOSE_MAKEFILE ON)

find_package(OpenCV QUIET)
find_package(ZLIB REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Gui)

qt6_add_resources(QT_RESOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/qml/qml.qrc
  ${CMAKE_CURRENT_SOURCE_DIR}/icons/icons.qrc
)

add_executable(offset WIN32 ${QT_RESOURCES})

target_sources(offset PRIVATE main.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/Logger.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/FsModel.cpp  
  ${CMAKE_CURRENT_SOURCE_DIR}/models/LocalFsModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/RemoteFsModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/BaseModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/models/TransferManager.cpp
)

if(OpenCV_FOUND)
  target_compile_definitions(offset PUBLIC OpenCV_FOUND)
  target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models/VideoRenderer.cpp)
endif(OpenCV_FOUND)

if(WIN32)
  target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/icons/resource.rc)
  target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models/DiskListModel.cpp)
endif(WIN32)

set_property(TARGET offset PROPERTY CXX_STANDARD 17)

target_include_directories(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models)

target_link_libraries(
  offset
  PRIVATE
  Qt6::Quick
  Qt6::QuickControls2
  Qt6::Gui
  rapidjson
  ZLIB::ZLIB
  OpenSSL::SSL
  OpenSSL::Crypto
  Crc32c::crc32c
)

if(OpenCV_FOUND)
  target_link_libraries(offset PRIVATE ${OpenCV_LIBS})
endif(OpenCV_FOUND)

if(WIN32)
  target_link_libraries(offset PRIVATE Ws2_32.lib VssApi.lib)
endif(WIN32)

#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DQT_QML_DEBUG")

#SET_TARGET_PROPERTIES(
#  offset
#  PROPERTIES
#  LINK_FLAGS
#  "/MANIFESTUAC:\"level='requireAdministrator' uiAccess='false'\" /SUBSYSTEM:WINDOWS"
#)