/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_XREPOKEY_H
#define SATSOLVER_XREPOKEY_H

#include <pool.h>
#include <repo.h>

/************************************************
 * XRepokey - eXternally visible Repokey
 *
 * we cannot use a Repokey pointer since it doesn't reference the Pool
 */

typedef struct _xrepokey {
  Repodata *repodata;
  int keynum;
} XRepokey;

XRepokey *xrepokey_new( Repodata *repodata, int keynum );
void xrepokey_free( XRepokey *xr );
Repokey *xrepokey_repokey( const XRepokey *xr );

#endif  /* SATSOLVER_XREPOKEY_H */
