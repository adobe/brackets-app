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

set(dir ${CMAKE_CURRENT_SOURCE_DIR}/../../../bin/linux)
set(EXECUTABLE_OUTPUT_PATH ${dir} CACHE PATH "Build directory" FORCE)

CONFIGURE_FILE(config.vala.cmake ${CMAKE_CURRENT_SOURCE_DIR}/config.vala)

set(VALA_SRC
        config.vala
        main.vala
        frame.vala
        browser.vala
        bracketswindow.vala
)

vala_precompile(VALA_C
    SOURCES
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

install(TARGETS
    brackets
RUNTIME
DESTINATION
    bin
)


