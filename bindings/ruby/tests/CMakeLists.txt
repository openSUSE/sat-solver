#
# CMakeLists.txt for sat-solver/bindings/ruby/tests
#

ENABLE_TESTING()

ADD_TEST(bindings_ruby_loading     ruby ${CMAKE_CURRENT_SOURCE_DIR}/loading.rb)
ADD_TEST(bindings_ruby_pool        ruby ${CMAKE_CURRENT_SOURCE_DIR}/pool.rb)
ADD_TEST(bindings_ruby_repo	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/repo.rb)
ADD_TEST(bindings_ruby_rpmdb	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/rpmdb.rb)

ADD_TEST(bindings_ruby_solvable	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/solvable.rb)
ADD_TEST(bindings_ruby_relation	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/relation.rb)
ADD_TEST(bindings_ruby_repodata	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/repodata.rb)

ADD_TEST(bindings_ruby_providers   ruby ${CMAKE_CURRENT_SOURCE_DIR}/providers.rb)

ADD_TEST(bindings_ruby_transaction ruby ${CMAKE_CURRENT_SOURCE_DIR}/transaction.rb)
ADD_TEST(bindings_ruby_covenants   ruby ${CMAKE_CURRENT_SOURCE_DIR}/covenants.rb)

ADD_TEST(bindings_ruby_solver	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/solver.rb)
ADD_TEST(bindings_ruby_decisions   ruby ${CMAKE_CURRENT_SOURCE_DIR}/decisions.rb)
#ADD_TEST(bindings_ruby_problems	   ruby ${CMAKE_CURRENT_SOURCE_DIR}/problems.rb)
ADD_TEST(bindings_ruby_solutions   ruby ${CMAKE_CURRENT_SOURCE_DIR}/solutions.rb)
