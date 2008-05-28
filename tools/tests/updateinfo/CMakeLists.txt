#
# CMakeLists.txt for sat-solver/tools/tests/updateinfo
#

ENABLE_TESTING()

ADD_TEST(tools_updateinfo_fedora-imlib ruby ${CMAKE_CURRENT_SOURCE_DIR}/testing.rb ${CMAKE_BINARY_DIR} fedora-imlib)
