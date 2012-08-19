find_package(PkgConfig)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(GTK REQUIRED gtk+-2.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(WEBKIT REQUIRED webkit-1.0)

set(CFLAGS
    ${GOBJECT_CFLAGS} ${GOBJECT_CFLAGS_OTHER}
    ${GIO_CFLAGS} ${GIO_CFLAGS_OTHER}
    ${GTK_CFLAGS} ${GTK_CFLAGS_OTHER}
    ${WEBKIT_CFLAGS} ${WEBKIT_CFLAGS_OTHER}
)
add_definitions(${CFLAGS})

set(LIBS
    ${GOBJECT_LIBRARIES}
    ${GIO_LIBRARIES}
    ${GTK_LIBRARIES}
    ${WEBKIT_LIBRARIES}
)
link_libraries(${LIBS})

set(LIB_PATHS
    ${GOBJECT_LIBRARY_DIRS}
    ${GIO_LIBRARY_DIRS}
    ${GTK_LIBRARY_DIRS}
    ${WEBKIT_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

include(CMakeParseArguments)

function(prepare_config)
    cmake_parse_arguments(ARGS "" "" "CONFIG_NAME;INDEX_PATH;SCRIPT_PATH" ${ARGN})
    CONFIGURE_FILE(config.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_CONFIG_NAME})
endfunction(prepare_config)

prepare_config(
    CONFIG_NAME "config.vala"
    INDEX_PATH  "/../../brackets/src/index.html";
    SCRIPT_PATH "/../../src/linux/brackets_extensions.js";
)

prepare_config(
    CONFIG_NAME "config_install.vala"
    INDEX_PATH  "/../share/brackets/src/index.html";
    SCRIPT_PATH "/../share/brackets/brackets_extensions.js";
)

set(VALA_SRC
        main.vala
        frame.vala
        browser.vala
        bracketswindow.vala
)

vala_precompile(VALA_C
    SOURCES
        config.vala
        ${VALA_SRC}
    PACKAGES
        gtk+-2.0
        gio-2.0
        webkit-1.0
    OPTIONS
        --vapidir ${PROJECT_SOURCE_DIR}/vala
        --pkg javascriptcore
)

add_executable(brackets ${VALA_C})

vala_precompile(VALA_C
    SOURCES
        config_install.vala
        ${VALA_SRC}
    PACKAGES
        gtk+-2.0
        gio-2.0
        webkit-1.0
    OPTIONS
        --vapidir ${PROJECT_SOURCE_DIR}/vala
        --pkg javascriptcore
)

add_executable(bracketsapp ${VALA_C})

set(dir ${CMAKE_CURRENT_SOURCE_DIR}/../../../bin/linux)
ADD_CUSTOM_COMMAND(
    TARGET brackets
    POST_BUILD
    COMMAND cp ARGS ${CMAKE_CURRENT_BINARY_DIR}/brackets ${dir}
    COMMENT "Copying brackets binary to the proper place..")

INSTALL(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/bracketsapp
        RENAME "brackets"
        DESTINATION "bin")

