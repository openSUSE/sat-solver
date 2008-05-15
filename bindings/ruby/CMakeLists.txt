#ADD_SUBDIRECTORY(tests)

# SWIG_OUPUT is per-target

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/satsolver_swig.c" )

MESSAGE(STATUS "Ruby executable: ${RUBY_EXECUTABLE}")
MESSAGE(STATUS "Ruby vendor arch dir: ${RUBY_VENDORARCH_DIR}")
MESSAGE(STATUS "Ruby include path: ${RUBY_INCLUDE_PATH}")

ADD_CUSTOM_COMMAND (
   OUTPUT  "${SWIG_OUTPUT}"
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Ruby..."
   COMMAND ${SWIG_EXECUTABLE} -ruby -features autodoc -autorename -o ${SWIG_OUTPUT} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)

SET(bindings_SRCS ${SWIG_OUTPUT} "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )

ADD_LIBRARY( satsolver_ruby SHARED ${bindings_SRCS} )

# name it 'satsolver.so'
#  and don't prefix with 'lib'
SET_TARGET_PROPERTIES( satsolver_ruby PROPERTIES OUTPUT_NAME "satsolver" PREFIX "" )

INCLUDE_DIRECTORIES( ${RUBY_INCLUDE_PATH} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( satsolver_ruby satsolver )
TARGET_LINK_LIBRARIES( satsolver_ruby appsatsolver )
TARGET_LINK_LIBRARIES( satsolver_ruby ${RUBY_LIBRARY} )
TARGET_LINK_LIBRARIES( satsolver_ruby ${RPMDB_LIBRARY} )

INSTALL(TARGETS satsolver_ruby LIBRARY DESTINATION ${RUBY_VENDORARCH_DIR})

