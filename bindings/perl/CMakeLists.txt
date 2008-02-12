#
# cmake description for satsolver Perl bindings
#
# !!Attn!!: This creates two files
#  1. _satsolverx.so
#  2. satsolverx.pm
# and the .pm file gets loaded. See bindings/perl/tests.
#

ADD_SUBDIRECTORY(tests)

EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccflags}" OUTPUT_VARIABLE PERL_CCFLAGS)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{archlib}.\"/CORE\"" OUTPUT_VARIABLE PERL_CORE_DIR)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorarch}" OUTPUT_VARIABLE PERL_VENDOR_ARCH)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorlib}" OUTPUT_VARIABLE PERL_VENDOR_LIB)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccdlflags}" OUTPUT_VARIABLE PERL_LINK_FLAGS)

MESSAGE(STATUS "Perl executable: ${PERL_EXECUTABLE}")
MESSAGE(STATUS "Perl core dir: ${PERL_CORE_DIR}")
MESSAGE(STATUS "Perl vendor arch dir: ${PERL_VENDOR_ARCH}")
MESSAGE(STATUS "Perl vendor lib dir: ${PERL_VENDOR_LIB}")

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" )
SET( SWIG_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/satsolver.i" )

ADD_DEFINITIONS( ${PERL_CCFLAGS} -Wno-unused -Wno-error )
LINK_DIRECTORIES( ${PERL_CORE_DIR} )

ADD_CUSTOM_COMMAND (
   OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Perl ..."
   COMMAND ${SWIG_EXECUTABLE} -perl -features autodoc -o ${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c ${CMAKE_CURRENT_SOURCE_DIR}/../satsolver.i
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)

ADD_CUSTOM_TARGET( glue
   DEPENDS ${SWIG_OUTPUT}
)

SET(satsolverx_SRCS "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )
ADD_LIBRARY( satsolverx SHARED ${satsolverx_SRCS} )
SET_TARGET_PROPERTIES( satsolverx PROPERTIES PREFIX "" )
ADD_DEPENDENCIES( satsolverx glue )

INCLUDE_DIRECTORIES( ${PERL_CORE_DIR} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( satsolverx satsolver )
TARGET_LINK_LIBRARIES( satsolverx appsatsolver )
TARGET_LINK_LIBRARIES( satsolverx perl )
TARGET_LINK_LIBRARIES( satsolverx ${DB43_LIBRARY} )

INSTALL(TARGETS satsolverx LIBRARY DESTINATION ${PERL_VENDOR_ARCH} )

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolverx.pm DESTINATION ${PERL_VENDOR_LIB} )
