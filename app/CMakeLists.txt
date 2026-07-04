#SET(CMAKE_VERBOSE_MAKEFILE ON)
find_package(CURL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(VTK CONFIG REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(Eigen3 CONFIG REQUIRED)
find_package(tinyxml2 CONFIG REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Gui Widgets OpenGLWidgets SerialPort)
find_package(PCL REQUIRED COMPONENTS io common search kdtree filters surface segmentation sample_consensus)

qt_standard_project_setup()
qt6_add_resources(QT_RESOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/qml.qrc
    ${CMAKE_CURRENT_SOURCE_DIR}/assets/assets.qrc
)

add_executable(offset main.cpp)

set(VTK_MODULES_USED
    VTK::CommonCore
    VTK::FiltersCore
    VTK::FiltersParallel
    VTK::RenderingCore
    VTK::RenderingOpenGL2
    VTK::GUISupportQtQuick
)

vtk_module_autoinit(TARGETS offset MODULES ${VTK_MODULES_USED})

target_sources(offset PRIVATE ${QT_RESOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/models/Logger.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/AppConfig.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/BaseModel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/ftp/FsModel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/ftp/LocalFsModel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/vtk/VtkQuickItem.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/ftp/RemoteFsModel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/cam/VideoRenderer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/SerialPortManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/floor/FloorManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/diff/CompareManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/ftp/TransferManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/diff/CompareFileModel.cpp
)

if(WIN32)
    target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/assets/resource.rc)
    target_sources(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/models/fxc/DiskListModel.cpp)
endif(WIN32)

set_property(TARGET offset PROPERTY CXX_STANDARD 23)

target_compile_definitions(offset PRIVATE ${PCL_DEFINITIONS})

target_include_directories(offset PRIVATE 
    ${PCL_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}/models
    ${CMAKE_CURRENT_SOURCE_DIR}/models/vtk
    ${CMAKE_CURRENT_SOURCE_DIR}/models/ftp
    ${CMAKE_CURRENT_SOURCE_DIR}/models/cam
    ${CMAKE_CURRENT_SOURCE_DIR}/models/fxc
    ${CMAKE_CURRENT_SOURCE_DIR}/models/diff
    ${CMAKE_CURRENT_SOURCE_DIR}/models/floor
)

target_link_libraries(offset PRIVATE
    rapidjson
    opencv_ml
    ZLIB::ZLIB
    opencv_dnn
    opencv_dpm
    opencv_hdf
    opencv_face
    opencv_core
    OpenSSL::SSL
    Eigen3::Eigen
    opencv_aruco
    opencv_bgsegm
    CURL::libcurl
    Crc32c::crc32c
    opencv_tracking
    OpenSSL::Crypto
    ${PCL_LIBRARIES}
    VTK::CommonCore
    VTK::FiltersCore
    VTK::FiltersParallel
    VTK::RenderingCore
    VTK::RenderingOpenGL2
    VTK::GUISupportQtQuick
    tinyxml2::tinyxml2
    Qt6::Gui
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    Qt6::SerialPort
    Qt6::OpenGLWidgets
    Qt6::QuickControls2
)

if(WIN32)
    target_link_libraries(offset PRIVATE
        ws2_32
        vssapi
    )
endif()

#target_compile_definitions(offset PRIVATE QT_QML_DEBUG)

#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DQT_QML_DEBUG")

#SET_TARGET_PROPERTIES(
#  offset
#  PROPERTIES
#  LINK_FLAGS
#  "/MANIFESTUAC:\"level='requireAdministrator' uiAccess='false'\" /SUBSYSTEM:WINDOWS"
#)