cmake_minimum_required(VERSION 2.6)
project(oekpool)

set(CMAKE_BUILD_TYPE Debug)

#set(CMAKE_VERBOSE_MAKEFILE ON)

file(GLOB OEKPOOL_SOURCES ./*.cpp)


FIND_PACKAGE(LibXml2)
if(LIBXML2_FOUND)
    include_directories(${LIBXML2_INCLUDE_DIR})
endif()

add_library(sockets STATIC IMPORTED)
set_property(TARGET sockets PROPERTY 
    IMPORTED_LOCATION  "${CMAKE_HOME_DIRECTORY}/lib/libSockets.a")
add_library(ldapcpp STATIC IMPORTED)
set_property(TARGET ldapcpp PROPERTY 
    IMPORTED_LOCATION  "${CMAKE_HOME_DIRECTORY}/lib/libldapcpp.a")

include_directories("lib/ldapc++" "lib/libSockets")


add_executable(oekpool ${OEKPOOL_SOURCES})

message(STATUS "LibXml2_LIBRARIES=${LIBXML2_LIBRARIES}")
target_link_libraries(oekpool sockets ldapcpp ${LIBXML2_LIBRARIES} ldap)

