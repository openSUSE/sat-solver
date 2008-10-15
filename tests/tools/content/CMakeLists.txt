#
# CMakeLists.txt for sat-solver/tools/tests/content
#

ENABLE_TESTING()

ADD_TEST(tools_content_os11beta3 ruby ${CMAKE_CURRENT_SOURCE_DIR}/testing.rb ${CMAKE_BINARY_DIR} os11-beta3-dvd-x86_64)
ADD_TEST(tools_content_os11_1    ruby ${CMAKE_CURRENT_SOURCE_DIR}/testing.rb ${CMAKE_BINARY_DIR} os11_1-new_product-dvd-i586)