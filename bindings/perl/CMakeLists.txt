#
# cmake description for satsolver Perl bindings
#
# !!Attn!!: This creates two files
#  1. _satsolverx.so
#  2. satsolverx.pm
# and the .pm file gets loaded. See bindings/perl/tests.
#

ADD_SUBDIRECTORY(tests)

#
# Can't use 'satsolver' here, already taken by src/CMakeLists.txt
#

SET( binding_NAME "satsolverx" )

EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccflags}" OUTPUT_VARIABLE PERL_CCFLAGS)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{archlib}.\"/CORE\"" OUTPUT_VARIABLE PERL_CORE_DIR)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorarch}" OUTPUT_VARIABLE PERL_VENDOR_ARCH)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{installvendorlib}" OUTPUT_VARIABLE PERL_VENDOR_LIB)
EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -e "use Config; print \$Config{ccdlflags}" OUTPUT_VARIABLE PERL_LINK_FLAGS)

MESSAGE(STATUS "Perl executable: ${PERL_EXECUTABLE}")
MESSAGE(STATUS "Perl core dir: ${PERL_CORE_DIR}")
MESSAGE(STATUS "Perl vendor arch dir: ${PERL_VENDOR_ARCH}")
MESSAGE(STATUS "Perl vendor lib dir: ${PERL_VENDOR_LIB}")

ADD_DEFINITIONS( ${PERL_CCFLAGS} -Wno-unused -Wno-error )
LINK_DIRECTORIES( ${PERL_CORE_DIR} )

if(COMMAND cmake_policy)
  cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)
	      

ADD_CUSTOM_COMMAND (
   OUTPUT  "${SWIG_OUTPUT}"
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Perl ..."
   COMMAND ${SWIG_EXECUTABLE} -perl -features autodoc -o ${SWIG_OUTPUT} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
)


SET(binding_SRCS ${SWIG_INPUT} "${CMAKE_SOURCE_DIR}/tools/repo_rpmdb.c" )

ADD_LIBRARY( ${binding_NAME} SHARED ${binding_SRCS} )
SET_TARGET_PROPERTIES( ${binding_NAME} PROPERTIES PREFIX "" )

INCLUDE_DIRECTORIES( ${PERL_CORE_DIR} ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

TARGET_LINK_LIBRARIES( ${binding_NAME} satsolver )
TARGET_LINK_LIBRARIES( ${binding_NAME} appsatsolver )
TARGET_LINK_LIBRARIES( ${binding_NAME} perl )
TARGET_LINK_LIBRARIES( ${binding_NAME} ${DB43_LIBRARY} )

INSTALL(TARGETS ${binding_NAME} LIBRARY DESTINATION ${PERL_VENDOR_ARCH} )

INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/${binding_NAME}.pm DESTINATION ${PERL_VENDOR_LIB} )
