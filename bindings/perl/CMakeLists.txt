#
# cmake description for satsolver Perl bindings
#
#

ADD_SUBDIRECTORY(tests)

MESSAGE(STATUS "Perl executable: ${PERL_EXECUTABLE}")
MESSAGE(STATUS "Perl lib dir: ${PERL_LIB_DIR}")
MESSAGE(STATUS "Perl site dir: ${PERL_LIB_DIR}/site-packages")

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" )
SET( SWIG_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/satsolver.i" )

ADD_CUSTOM_COMMAND (
   OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Python ..."
   COMMAND ${SWIG_EXECUTABLE} -perl -features autodoc -o ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c -I${CMAKE_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/../satsolver.i
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

INCLUDE_DIRECTORIES( ${PERL_INCLUDE_PATH} ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( _satsolverx satsolver )
TARGET_LINK_LIBRARIES( _satsolverx ${PERL_LIBRARIES} )
TARGET_LINK_LIBRARIES( _satsolverx ${DB43_LIBRARY} )

INSTALL(TARGETS _satsolverx LIBRARY DESTINATION ${PERL_LIB_DIR}/site-packages)

#INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolverx.py DESTINATION ${PERL_LIB_DIR}/site-packages )
