/*
 * applayer.c
 * test applayer functions of appsatsolver library
 * 
 */

#include <assert.h>

#include "applayer.h"

int
main( int argc, char *argv[] )
{
  Pool *pool = pool_create();
  assert( my_id2str( pool, STRID_NULL ) == NULL );
  const char *empty = my_id2str( pool, STRID_EMPTY );
  assert( empty && (*empty == 0));
  
  return 0;
}
