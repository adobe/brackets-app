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

INSTALL(FILES ../../brackets/LICENSE
              ../../brackets/README.md
              brackets_extensions.js
        DESTINATION "share/brackets")

INSTALL(FILES ../../brackets/src/styles/images/brackets_icon.png
        RENAME "brackets.png"
        DESTINATION "share/brackets")

INSTALL(CODE "EXECUTE_PROCESS(COMMAND desktop-file-install
                                    --set-key=Exec --set-value=${CMAKE_INSTALL_PREFIX}/bin/brackets
                                    --dir=${CMAKE_INSTALL_PREFIX}/share/applications
                                    --set-icon=${CMAKE_INSTALL_PREFIX}/share/brackets/brackets.png
                                    ../brackets.desktop)") #we're in build dir now


        
