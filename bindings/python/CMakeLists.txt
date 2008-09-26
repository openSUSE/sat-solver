#
# cmake description for satsolver Python bindings
#
# !!Attn!!: This creates two files
#  1. satsolver.so
#  2. satsolver.py
# and the .py file gets imported. See bindings/python/tests.
#

ADD_SUBDIRECTORY(tests)

# SWIG_OUPUT is per-target
SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/satsolver_python.c" )

FIND_PACKAGE(PythonInterp REQUIRED)
EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c "from sys import stdout; from distutils import sysconfig; stdout.write(sysconfig.get_python_lib())" OUTPUT_VARIABLE PYTHON_LIB_DIR)

IF (NOT PYTHON_SITEDIR)
  SET (PYTHON_SITEDIR ${PYTHON_LIB_DIR})
ENDIF (NOT PYTHON_SITEDIR)

MESSAGE(STATUS "Python executable: ${PYTHON_EXECUTABLE}")
MESSAGE(STATUS "Python lib dir: ${PYTHON_LIB_DIR}")
MESSAGE(STATUS "Python site dir: ${PYTHON_SITEDIR}")

ADD_CUSTOM_COMMAND (
   OUTPUT  "${SWIG_OUTPUT}"
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Python ..."
   COMMAND ${SWIG_EXECUTABLE} -python -features autodoc -o ${SWIG_OUTPUT} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)

SET(binding_SRCS "${SWIG_OUTPUT}" "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )

ADD_LIBRARY( satsolver_python SHARED ${binding_SRCS} )
# name it '_satsolver.so'
#  and don't prefix with 'lib'
SET_TARGET_PROPERTIES( satsolver_python PROPERTIES PREFIX "" OUTPUT_NAME "_satsolver")

INCLUDE_DIRECTORIES( ${PYTHON_INCLUDE_PATH} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( satsolver_python satsolver )
TARGET_LINK_LIBRARIES( satsolver_python appsatsolver )
TARGET_LINK_LIBRARIES( satsolver_python ${PYTHON_LIBRARIES} )
TARGET_LINK_LIBRARIES( satsolver_python ${RPMDB_LIBRARY} )

INSTALL(TARGETS satsolver_python LIBRARY DESTINATION ${PYTHON_SITEDIR})

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolver.py DESTINATION ${PYTHON_SITEDIR} )
