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

#include <stdarg.h>
#include <stdlib.h>
#include "applayer.h"

/************************************************
 * string handling
 *
 */

/* helper for string representation, snprintf + strdup */

char *to_string(const char *format, ...)
{
  char buf[2048];
  va_list args;
  va_start(args, format);
  vsnprintf(buf, sizeof(buf), format, args);
  return strdup(buf);
}

struct debugdata {
  Pool *pool;
  int debugmask;
  char *buf;
  int length;
};

static struct debugdata dd;

static void
app_debugcallback(struct _Pool *p, void *data, int type, const char *str)
{
  struct debugdata *ddp = (struct debugdata *)data;
  int len = strlen(str);
  ddp->buf = realloc(ddp->buf, ddp->length + len + 1);
  if (ddp->length == 0) *ddp->buf = 0;
  strcat(ddp->buf, str);
  ddp->length += len;
}

void
app_debugstart(Pool *p, int type)
{
  dd.buf = NULL;
  dd.length = 0;
  dd.debugmask = p->debugmask;
  p->debugmask = type;
  p->debugcallback = app_debugcallback;
  p->debugcallbackdata = &dd;
  dd.pool = p;
}

char *
app_debugend()
{
  dd.pool->debugcallback = NULL;
  dd.pool->debugmask = dd.debugmask;
  return dd.buf;
}

/************************************************
 * Id
 *
 */

const char *
my_id2str( const Pool *pool, Id id )
{
  if (id == STRID_NULL)
    return NULL;
  if (id == STRID_EMPTY)
    return "";
  return id2str( pool, id );
}

/************************************************
 * Pool
 *
 */

unsigned int
pool_xsolvables_count( const Pool *pool )
{
  const Solvable *s;
  Id p;
  int count = 0;
  /* skip Id 0 since it is reserved
   * skip Id 1 since it is the system solvable and not
   *   accessible to the outside
   */
  for (p = 2, s = pool->solvables + p; p < pool->nsolvables; p++, s++)
    {
      if (!s)
	continue;
      if (!s->name)
        continue;
      ++count;
    }
  
  return count;
}

void
pool_xsolvables_iterate( Pool *pool, int (*callback)(const XSolvable *xs, void *user_data), void *user_data)
{
  const Solvable *s;
  Id p;
  /* skip Id 0 and Id 1, see pool_count() above */
  for (p = 2, s = pool->solvables + p; p < pool->nsolvables; p++, s++)
    {
      if (!s)
	continue;
      if (!s->name)
        continue;
      if (callback( xsolvable_new( pool, p ), user_data ) )
	break;
    }
}

