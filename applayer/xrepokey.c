/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * XRepokey - eXternally visible Repokey
 *
 * see xrepokey.h for docs.
 */

#include <stdlib.h>
#include <policy.h>

#include "xrepokey.h"

XRepokey *
xrepokey_new( Repokey *key, Repo *repo, Repodata *repodata )
{
  XRepokey *xrepokey = (XRepokey *)malloc( sizeof( XRepokey ));
  xrepokey->key = key;
  xrepokey->repo = repo;
  xrepokey->repodata = repodata;

  return xrepokey;
}


void
xrepokey_free( XRepokey *xr )
{
  free( xr );
}


Repokey *
xrepokey_repokey( const XRepokey *xr )
{
  return xr->key;
}

