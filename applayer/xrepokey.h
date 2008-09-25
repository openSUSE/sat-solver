/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#ifndef SATSOLVER_XREPOKEY_H
#define SATSOLVER_XREPOKEY_H

#include "pool.h"
#include "repo.h"

/************************************************
 * XRepokey - eXternally visible Repokey
 *
 * we cannot just use a Repokey pointer since it doesn't reference the Pool
 * And key might be internal (no repodata) or external (defined in repodata)
 * So we need
 *  - the Repokey
 *  - the Repo (it has the Pool backref, and probably many Repodatas)
 *  - the Repodata (for externally defined Repokeys)
 */

typedef struct _xrepokey {
  Repokey *key;
  Repo *repo;
  Repodata *repodata;
} XRepokey;

/* if repodata == 0, key is internal
 * if repodata != 0, key is external (per repodata)
 */
XRepokey *xrepokey_new( Repokey *key, Repo *repo, Repodata *repodata );
void xrepokey_free( XRepokey *xr );
Repokey *xrepokey_repokey( const XRepokey *xr );

#endif  /* SATSOLVER_XREPOKEY_H */
