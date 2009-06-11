
cmake_minimum_required(VERSION 2.6)
project(vmchooser)

set(CMAKE_BUILD_TYPE Debug)

#set(CMAKE_VERBOSE_MAKEFILE ON)
set(OPENSLX_ROOT "../../../..")
#set(OPENSLX_ROOT "~/hiwi/openslx")

file(GLOB VMCHOOSER_SOURCES *.cxx)

set(Boost_USE_STATIC_LIBS ON)
find_package( Boost COMPONENTS "filesystem" "regex" "system" )

if(Boost_FOUND)
    link_directories(${Boost_LIBRARY_DIRS}) 
    include_directories(${Boost_INCLUDE_DIRS})
endif()


include_directories(. ../fltk/ ../libxml2/include)

add_executable(vmchooser ${VMCHOOSER_SOURCES})


add_library(fltk2 STATIC IMPORTED)
add_library(fltk2_images STATIC IMPORTED)
add_library(xml2 STATIC IMPORTED)

set_property(TARGET fltk2 PROPERTY IMPORTED_LOCATION  "../fltk/lib/libfltk2.a")
set_property(TARGET fltk2_images PROPERTY IMPORTED_LOCATION  "../fltk/lib/libfltk2_images.a")
set_property(TARGET xml2 PROPERTY IMPORTED_LOCATION "../libxml2/libs/libxml2.a")


#message(STATUS "Boost_LIBRARIES=${Boost_LIBRARIES}")
target_link_libraries(vmchooser fltk2 fltk2_images xml2
        Xi Xinerama X11 Xft ${Boost_LIBRARIES})

install(TARGETS vmchooser RUNTIME DESTINATION 
	"${OPENSLX_ROOT}/openslx/trunk/os-plugins/plugins/vmchooser/files/") 