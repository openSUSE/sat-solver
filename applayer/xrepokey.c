/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

/************************************************
 * XRepokey - eXternally visible Repokey
 *
 * we cannot use a Repokey pointer since it doesn't reference the Pool
 */

#include <stdlib.h>
#include <policy.h>

#include "xrepokey.h"

XRepokey *
xrepokey_new( Repodata *repodata, int keynum )
{
  XRepokey *xrepokey = (XRepokey *)malloc( sizeof( XRepokey ));
  xrepokey->repodata = repodata;
  xrepokey->keynum = keynum;

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
  return xr->repodata->keys + xr->keynum;
}

