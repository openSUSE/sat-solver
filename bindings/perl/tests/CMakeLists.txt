#
# CMakeLists.txt for sat-solver/bindings/perl/tests
#

ENABLE_TESTING()

ADD_TEST(bindings_perl_loading     perl ${CMAKE_CURRENT_SOURCE_DIR}/loading.pl)
ADD_TEST(bindings_perl_identical   perl ${CMAKE_CURRENT_SOURCE_DIR}/identical.pl)
ADD_TEST(bindings_perl_providers   perl ${CMAKE_CURRENT_SOURCE_DIR}/providers.pl)
ADD_TEST(bindings_perl_example-new  perl ${CMAKE_CURRENT_SOURCE_DIR}/example-new.pl)
