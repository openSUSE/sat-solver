#
# CMakeLists.txt for sat-solver/bindings/ruby/tests
#

ENABLE_TESTING()

ADD_TEST(bindings_ruby_loading     ruby -C ${CMAKE_CURRENT_SOURCE_DIR} loading.rb)
ADD_TEST(bindings_ruby_pool        ruby -C ${CMAKE_CURRENT_SOURCE_DIR} pool.rb)
ADD_TEST(bindings_ruby_repo	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} repo.rb)
ADD_TEST(bindings_ruby_rpmdb	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} rpmdb.rb)

ADD_TEST(bindings_ruby_solvable	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} solvable.rb)
ADD_TEST(bindings_ruby_relation	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} relation.rb)
ADD_TEST(bindings_ruby_repodata	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} repodata.rb)

ADD_TEST(bindings_ruby_providers   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} providers.rb)

ADD_TEST(bindings_ruby_request     ruby -C ${CMAKE_CURRENT_SOURCE_DIR} request.rb)
ADD_TEST(bindings_ruby_covenants   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} covenants.rb)

ADD_TEST(bindings_ruby_solver	   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} solver.rb)
ADD_TEST(bindings_ruby_decisions   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} decisions.rb)
ADD_TEST(bindings_ruby_reasons     ruby -C ${CMAKE_CURRENT_SOURCE_DIR} reasons.rb)
ADD_TEST(bindings_ruby_problems    ruby -C ${CMAKE_CURRENT_SOURCE_DIR} problems.rb)
ADD_TEST(bindings_ruby_solutions   ruby -C ${CMAKE_CURRENT_SOURCE_DIR} solutions.rb)
