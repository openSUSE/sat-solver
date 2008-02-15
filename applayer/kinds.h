/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * kinds.h
 * 
 * Kind identification for package/pattern/patch/product
 */

#ifndef SATSOLVER_KINDS_H
#define SATSOLVER_KINDS_H

typedef enum {
  KIND_PACKAGE = 0,
  KIND_PRODUCT = 5,         /* strlen("prod:") */
  KIND_PATCH = 6,           /* strlen("patch:") */
  KIND_SOURCE = 7,          /* strlen("source:") */
  KIND_PATTERN = 8,         /* strlen("pattern:") */
  KIND_NOSOURCE = 9,        /* strlen("nosource:") */
  _KIND_MAX
} solvable_kind;

extern const char *kind_prefix( solvable_kind kind );

#endif /* SATSOLVER_KINDS_H */
