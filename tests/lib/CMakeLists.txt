
SET(CHECK_MAJOR_VERSION 0)
SET(CHECK_MINOR_VERSION 9)
SET(CHECK_MICRO_VERSION 5)

set ( CMAKE_C_FLAGS     "${CMAKE_C_FLAGS} -Wall" )
set ( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -g -O3" )
set ( CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS} -g3 -O0" )

INCLUDE (CheckIncludeFiles)
CHECK_INCLUDE_FILES (malloc.h HAVE_MALLOC_H)
CHECK_INCLUDE_FILES (stdint.h HAVE_STDINT_H)
CHECK_INCLUDE_FILES (unistd.h HAVE_UNISTD_H)

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/check.h.in ${CMAKE_CURRENT_BINARY_DIR}/check.h @ONLY)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h @ONLY)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})

SET(CHECK_SOURCES
 check.c
 check_error.c
 check_error.h
 ${CMAKE_CURRENT_BINARY_DIR}/check.h
 check_impl.h
 check_list.c
 check_list.h
 check_log.c
 check_log.h
 check_msg.c
 check_msg.h
 check_pack.c
 check_pack.h
 check_print.c
 check_print.h
 check_run.c
 check_str.c
 check_str.h
)

ADD_LIBRARY(check ${CHECK_SOURCES})

