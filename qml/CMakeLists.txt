cmake_minimum_required(VERSION 3.16)

project(untitled VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Gui)

qt6_add_resources(QT_RESOURCES 
  ${CMAKE_SOURCE_DIR}/qml/qml.qrc
  ${CMAKE_SOURCE_DIR}/icons/icons.qrc
)

add_executable(
  offset 
  main.cpp
  ${CMAKE_SOURCE_DIR}/model/BaseModel.cpp
  ${CMAKE_SOURCE_DIR}/model/DiskListModel.cpp
  ${QT_RESOURCES}
)

target_include_directories(offset PRIVATE ${CMAKE_SOURCE_DIR}/model)

target_link_libraries(offset
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Gui)