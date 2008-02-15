/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#include "kinds.h"

/*
 * solvable_kind -> string prefix
 *
 */

static const char *kindprefix_data[] = {
  0, 0, 0, 0, 0, 
  "prod:", 
  "patch:",
  "source:",
  "pattern:",
  "nosource"
};

const char *
kind_prefix( solvable_kind kind )
{
  if (kind >= _KIND_MAX)
    return 0;
  return kindprefix_data[kind];
}
