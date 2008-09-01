/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/*
 * Sat solver application layer
 *
 * Helper functions
 *
 */


#ifndef SATSOLVER_APPLAYER_H
#define SATSOLVER_APPLAYER_H

#include "pool.h"

#include "xsolvable.h"

/************************************************
 * Id
 *
 */

const char *my_id2str( Pool *pool, Id id );

/************************************************
 * Pool
 *
 */

unsigned int pool_size( Pool *pool );
void pool_xsolvables_iterate( Pool *pool, int (*callback)(const XSolvable *xs));

#endif  /* SATSOLVER_APPLAYER_H */
