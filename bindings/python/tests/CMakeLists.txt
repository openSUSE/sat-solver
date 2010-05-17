#
# CMakeLists.txt for sat-solver/bindings/python/tests
#

ENABLE_TESTING()

ADD_TEST(bindings_python_loading  python ${CMAKE_CURRENT_SOURCE_DIR}/loading.py)
