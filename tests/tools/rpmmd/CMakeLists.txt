#
# CMakeLists.txt for sat-solver/tools/tests/rpmmd
#

ENABLE_TESTING()

ADD_TEST(tools_rpmmd_pattern ruby ${CMAKE_CURRENT_SOURCE_DIR}/testing.rb ${CMAKE_BINARY_DIR} pattern)
