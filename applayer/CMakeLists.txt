#
# CMakeLists.txt for sat-solver/applayer
#

ADD_SUBDIRECTORY(tests)

SET(libappsatsolver_SRCS job.c applayer.c covenant.c decision.c dependency.c
      kinds.c problem.c relation.c ruleinfo.c solution.c step.c request.c xrepokey.c xsolvable.c)

ADD_LIBRARY(appsatsolver STATIC ${libappsatsolver_SRCS})

SET(libappsatsolver_HEADERS job.h applayer.h covenant.h decision.h dependency.h
      kinds.h problem.h relation.h solution.h step.h request.h ruleinfo.h xrepokey.h xsolvable.h)

SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -Wall -Werror" )

INSTALL(  FILES ${libappsatsolver_HEADERS} DESTINATION "${CMAKE_INSTALL_PREFIX}/include/satsolver" )
INSTALL(TARGETS appsatsolver LIBRARY DESTINATION ${LIB_INSTALL_DIR} ARCHIVE DESTINATION ${LIB_INSTALL_DIR})
