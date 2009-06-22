#
# cmake description for satsolver Perl bindings
#
# !!Attn!!: This creates two files
#  1. satsolver.so
#  2. satsolver.pm
# and the .pm file gets loaded. See bindings/perl/tests.
#

ADD_SUBDIRECTORY(tests)

# SWIG_OUPUT is per-target
SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/satsolver_perl.c" )

EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccflags}" OUTPUT_VARIABLE PERL_CCFLAGS)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{archlib}.\"/CORE\"" OUTPUT_VARIABLE PERL_CORE_DIR)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorarch}" OUTPUT_VARIABLE PERL_VENDOR_ARCH)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorlib}" OUTPUT_VARIABLE PERL_VENDOR_LIB)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccdlflags}" OUTPUT_VARIABLE PERL_LINK_FLAGS)

MESSAGE(STATUS "Perl executable: ${PERL_EXECUTABLE}")
MESSAGE(STATUS "Perl core dir: ${PERL_CORE_DIR}")
MESSAGE(STATUS "Perl vendor arch dir: ${PERL_VENDORDIR}")

ADD_DEFINITIONS( ${PERL_CCFLAGS} -Wno-unused -Wno-error -Wno-nonnull)
LINK_DIRECTORIES( ${PERL_CORE_DIR} )

if(COMMAND cmake_policy)
  cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)
	      

ADD_CUSTOM_COMMAND (
   OUTPUT  "${SWIG_OUTPUT}"
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Perl ..."
   COMMAND ${SWIG_EXECUTABLE} -perl -o ${SWIG_OUTPUT} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)


SET(binding_SRCS ${SWIG_OUTPUT} "${CMAKE_SOURCE_DIR}/ext/repo_rpmdb.c" )

ADD_LIBRARY( satsolver_perl SHARED ${binding_SRCS} )
# name it 'satsolver.so'
#  and don't prefix with 'lib'
SET_TARGET_PROPERTIES( satsolver_perl PROPERTIES PREFIX "" OUTPUT_NAME "satsolver")

INCLUDE_DIRECTORIES( ${PERL_CORE_DIR} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/ext)

TARGET_LINK_LIBRARIES( satsolver_perl satsolver )
TARGET_LINK_LIBRARIES( satsolver_perl appsatsolver )
TARGET_LINK_LIBRARIES( satsolver_perl ${PERL_LIBRARY} )
TARGET_LINK_LIBRARIES( satsolver_perl ${RPMDB_LIBRARY} )

INSTALL(TARGETS satsolver_perl LIBRARY DESTINATION ${PERL_VENDOR_ARCH} )

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/satsolver.pm DESTINATION ${PERL_VENDOR_LIB} )
