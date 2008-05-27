#
# CMakeLists.txt for sat-solver/tools/tests/updateinfo
#

ENABLE_TESTING()

ADD_TEST(updateinfo1 ruby ${CMAKE_CURRENT_SOURCE_DIR}/testing.rb ${CMAKE_BINARY_DIR} fedora-imlib)
