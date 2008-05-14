FIND_PACKAGE(SWIG)
FIND_PACKAGE(Ruby)
FIND_PACKAGE(PythonLibs)

# doesn't work yet :-(
# CMake problem, FindPerlLibs.cmake is in a _really_ bad, bad state :-((
# see e.g. http://www.vtk.org/Bug/print_bug_page.php?bug_id=3665
#FIND_PACKAGE(PerlLibs)
FIND_PACKAGE(Perl)

IF (RUBY_LIBRARY AND RUBY_INCLUDE_PATH)
    ADD_SUBDIRECTORY(ruby)
ENDIF(RUBY_LIBRARY AND RUBY_INCLUDE_PATH)

IF (PYTHON_LIBRARY)
  ADD_SUBDIRECTORY(python)
ENDIF(PYTHON_LIBRARY)

IF (PERL_EXECUTABLE)
  MESSAGE(STATUS "Perl executable: ${PERL_EXECUTABLE}")
  ADD_SUBDIRECTORY(perl)
ENDIF (PERL_EXECUTABLE)

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libsatsolver_wrap.c" )
SET( SWIG_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/satsolver.i" )
ADD_DEPENDENCIES( satsolverx "${CMAKE_CURRENT_SOURCE_DIR}/*.i" )
