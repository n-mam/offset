set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Gui)

qt6_add_resources(QT_RESOURCES 
  ${CMAKE_CURRENT_SOURCE_DIR}/qml/qml.qrc
  ${CMAKE_CURRENT_SOURCE_DIR}/icons/icons.qrc
)

add_executable(
  offset 
  main.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/model/BaseModel.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/model/DiskListModel.cpp
  ${QT_RESOURCES}
)

target_include_directories(offset PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/model)

target_link_libraries(
  offset
  PRIVATE
  Qt6::Quick
  Qt6::QuickControls2
  Qt6::Gui
  rapidjson
  OpenSSL::SSL
  OpenSSL::Crypto
  Crc32c::crc32c
)