project("brackets" C)
cmake_minimum_required(VERSION 2.6)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/Vala_CMake/vala)

find_package(Vala REQUIRED)
include(${VALA_USE_FILE})

add_subdirectory(src)

INSTALL(DIRECTORY ../../brackets/src
        DESTINATION "share/brackets")

INSTALL(DIRECTORY ../../brackets/test
        DESTINATION "share/brackets")

INSTALL(FILES ../../brackets/LICENSE ../../brackets/README.md
        DESTINATION "share/brackets")
        
