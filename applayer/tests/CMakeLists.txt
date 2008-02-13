#
# CMakeLists.txt for sat-solver/applayer/tests
#

INCLUDE_DIRECTORIES( . ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/applayer ${CMAKE_SOURCE_DIR}/tools )

SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror" )

ADD_EXECUTABLE( applayer applayer.c )
TARGET_LINK_LIBRARIES( applayer satsolver appsatsolver )
