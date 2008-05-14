#
# cmake description for satsolver Python bindings
#
# !!Attn!!: This creates two files
#  1. ${binding_NAME}.so
#  2. satsolverx.py
# and the .py file gets imported. See bindings/python/tests.
#

ADD_SUBDIRECTORY(tests)

#
# Can't use 'satsolver' here, already taken by src/CMakeLists.txt
#

SET( binding_NAME "_satsolverx" )


FIND_PACKAGE(PythonInterp)
EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(sys.path[2])" OUTPUT_VARIABLE PYTHON_LIB_DIR)

MESSAGE(STATUS "Python executable: ${PYTHON_EXECUTABLE}")
MESSAGE(STATUS "Python lib dir: ${PYTHON_LIB_DIR}")
MESSAGE(STATUS "Python site dir: ${PYTHON_LIB_DIR}/site-packages")

ADD_CUSTOM_COMMAND (
   OUTPUT  "${SWIG_OUTPUT}"
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Python ..."
   COMMAND ${SWIG_EXECUTABLE} -python -features autodoc -o ${SWIG_OUTPUT} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)

SET(binding_SRCS "${SWIG_OUTPUT}" "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )

ADD_LIBRARY( ${binding_NAME} SHARED ${binding_SRCS} )
SET_TARGET_PROPERTIES( ${binding_NAME} PROPERTIES PREFIX "" )

INCLUDE_DIRECTORIES( ${PYTHON_INCLUDE_PATH} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( ${binding_NAME} satsolver )
TARGET_LINK_LIBRARIES( ${binding_NAME} appsatsolver )
TARGET_LINK_LIBRARIES( ${binding_NAME} ${PYTHON_LIBRARIES} )
TARGET_LINK_LIBRARIES( ${binding_NAME} ${DB43_LIBRARY} )

INSTALL(TARGETS ${binding_NAME} LIBRARY DESTINATION ${PYTHON_LIB_DIR}/site-packages)

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolverx.py DESTINATION ${PYTHON_LIB_DIR}/site-packages )
