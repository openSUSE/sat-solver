#
# CMakeLists.txt for sat-solver/bindings/perl/tests
#

ENABLE_TESTING()

ADD_TEST(bindings_perl_loading     perl ${CMAKE_CURRENT_SOURCE_DIR}/loading.pl)
