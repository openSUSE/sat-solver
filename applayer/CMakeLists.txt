#
# CMakeLists.txt for sat-solver/applayer
#

ADD_SUBDIRECTORY(tests)

SET(libappsatsolver_SRCS action.c applayer.c covenant.c decision.c dependency.c
      problem.c relation.c solution.c transaction.c xsolvable.c)

ADD_LIBRARY(appsatsolver STATIC ${libappsatsolver_SRCS})

SET(libappsatsolver_HEADERS action.h applayer.h covenant.h decision.h dependency.h
      problem.h relation.h solution.h transaction.h xsolvable.h)

SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -Wall -Werror" )

INSTALL(  FILES ${libappsatsolver_HEADERS} DESTINATION "${CMAKE_INSTALL_PREFIX}/include/satsolver" )
INSTALL(TARGETS appsatsolver LIBRARY DESTINATION ${LIB_INSTALL_DIR} ARCHIVE DESTINATION ${LIB_INSTALL_DIR})
