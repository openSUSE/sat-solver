/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_SOLUTION_H
#define SATSOLVER_SOLUTION_H

/************************************************
 * Solution
 *
 * A possible solution to a Problem.
 *
 * For each reported Problem, the Solver might generate
 * one or more Solutions to make the Transaction solvable.
 *
 */

#include "pool.h"

enum solutions {
  SOLUTION_UNKNOWN = 0,
  SOLUTION_NOKEEP_INSTALLED,
  SOLUTION_NOINSTALL_SOLV,
  SOLUTION_NOREMOVE_SOLV,
  SOLUTION_NOFORBID_INSTALL,
  SOLUTION_NOINSTALL_NAME,
  SOLUTION_NOREMOVE_NAME,
  SOLUTION_NOINSTALL_REL,
  SOLUTION_NOREMOVE_REL,
  SOLUTION_NOUPDATE,
  SOLUTION_ALLOW_DOWNGRADE,
  SOLUTION_ALLOW_ARCHCHANGE,
  SOLUTION_ALLOW_VENDORCHANGE,
  SOLUTION_ALLOW_REPLACEMENT,
  SOLUTION_ALLOW_REMOVE
};

typedef struct _Solution {
  Pool *pool;
  enum solutions solution;
  Id s1;
  Id n1;
  Id s2;
  Id n2;
} Solution;

Solution *solution_new( Pool *pool, int solution, Id s1, Id n1, Id s2, Id n2 );
void solution_free( Solution *s );

#endif  /* SATSOLVER_SOLUTION_H */
