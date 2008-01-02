#
# cmake description for satsolver Python bindings
#
# !!Attn!!: This creates two files
#  1. _satsolverx.so
#  2. satsolverx.py
# and the .py file gets imported. See bindings/python/tests.
#

ADD_SUBDIRECTORY(tests)

EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c 'import sys; print sys.path[2]' OUTPUT_VARIABLE PYTHON_LIB_DIR)

MESSAGE(STATUS "Python executable: ${PYTHON_EXECUTABLE}")
MESSAGE(STATUS "Python lib dir: ${PYTHON_LIB_DIR}")
MESSAGE(STATUS "Python site dir: ${PYTHON_LIB_DIR}/site-packages")

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" )
SET( SWIG_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/satsolver.i" )

ADD_CUSTOM_COMMAND (
   OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Python ..."
   COMMAND ${SWIG_EXECUTABLE} -python -features autodoc -o ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c -I${CMAKE_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/../satsolver.i
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)

ADD_CUSTOM_TARGET( glue
   DEPENDS ${SWIG_OUTPUT}
)

SET(satsolverx_SRCS "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )
ADD_LIBRARY( _satsolverx SHARED ${satsolverx_SRCS} )
SET_TARGET_PROPERTIES( _satsolverx PROPERTIES PREFIX "" )
ADD_DEPENDENCIES( _satsolverx glue )

INCLUDE_DIRECTORIES( ${PYTHON_INCLUDE_PATH} ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( _satsolverx satsolver )
TARGET_LINK_LIBRARIES( _satsolverx ${PYTHON_LIBRARIES} )
TARGET_LINK_LIBRARIES( _satsolverx ${DB43_LIBRARY} )

INSTALL(TARGETS _satsolverx LIBRARY DESTINATION ${PYTHON_LIB_DIR}/site-packages)

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolverx.py DESTINATION ${PYTHON_LIB_DIR}/site-packages )
