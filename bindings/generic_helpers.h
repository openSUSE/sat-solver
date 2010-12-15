#ifndef GENERIC_HELPERS_H
#define GENERIC_HELPERS_H

/*
 * iterating over (x)solvables ('yield' in Ruby)
 * (used by Pool, Repo and Solver)
 */

static int
generic_xsolvables_iterate_callback( const XSolvable *xs, void *user_data )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*)xs, SWIGTYPE_p__Solvable, 0) );
#else
  AddPtrIndex(((PtrIndex *)user_data),const XSolvable **,xs);
#endif
  return 0;
}


/*
 * create Dataiterator
 * (used by dataiterator.i and pool.search)
 */

static Dataiterator *
swig_dataiterator_new(Pool *pool, Repo *repo, const char *match, int option, XSolvable *xs, const char *keyname)
{
    Dataiterator *di = calloc(1, sizeof( Dataiterator ));
    Solvable *s = 0;
    /* cope with pool or repo being NULL */
    if (!pool) {
      if (!repo) {
        /* raise exception (FIXME) */
      }
      pool = repo->pool;
    }
    if (xs) s = xsolvable_solvable(xs);
    dataiterator_init(di, pool, repo, s ? s - s->repo->pool->solvables : 0, keyname && pool ? str2id(pool, keyname, 0) : 0, match, option);
    return di;
}


/*
 * destroy Dataiterator
 */
void
swig_dataiterator_free(Dataiterator *di)
{
    dataiterator_free(di);
    free( di );
}


/* convert Dataiterator to target value
 * if *more != 0 on return, value is incomplete
 */

static Swig_Type
dataiterator_value( Dataiterator *di )
{
  Swig_Type value = Swig_Null;

  /*
   * !! keep the order of case statements according to knownid.h !!
   */

  switch( di->key->type )
    {
      case REPOKEY_TYPE_VOID:
        value = Swig_True;
      break;
      case REPOKEY_TYPE_CONSTANT:
      case REPOKEY_TYPE_NUM:
      case REPOKEY_TYPE_U32:
        value = Swig_Int( di->kv.num );
      break;
      case REPOKEY_TYPE_CONSTANTID:
        value = Swig_String( dep2str( di->repo->pool, di->kv.id ) );
      break;
      case REPOKEY_TYPE_ID:
        if (di->data && di->data->localpool)
	  value = Swig_String( stringpool_id2str( &di->data->spool, di->kv.id ) );
	else
	  value = Swig_String( id2str( di->repo->pool, di->kv.id ) );
      break;
      case REPOKEY_TYPE_DIR:
        fprintf(stderr, "REPOKEY_TYPE_DIR: unhandled\n");
        value = Swig_Null;
      break;
      case REPOKEY_TYPE_STR:
        value = Swig_String( di->kv.str );
      break;
      case REPOKEY_TYPE_IDARRAY:
      {
        Swig_Type result = Swig_Array();
        do {
	  if (di->data && di->data->localpool)
	    Swig_Append( result, Swig_String( stringpool_id2str(&di->data->spool, di->kv.id ) ) );
	  else
	    Swig_Append( result, Swig_String( id2str( di->repo->pool, di->kv.id ) ) );
	}
	while (dataiterator_step(di));
	value = result;
      }
      break;
      case REPOKEY_TYPE_REL_IDARRAY:
        fprintf(stderr, "REPOKEY_TYPE_REL_IDARRAY: unhandled\n");
        value = Swig_Null;
      break;
      case REPOKEY_TYPE_DIRSTRARRAY:
	if (di->data)
	  value = Swig_String( repodata_dir2str(di->data, di->kv.id, di->kv.str) );
	else
	  fprintf(stderr, "REPOKEY_TYPE_DIRSTRARRAY: without repodata\n");
	break;
      case REPOKEY_TYPE_DIRNUMNUMARRAY:
        value = Swig_Array();
	if (di->data)
	{
	  Swig_Append( value, Swig_String(repodata_dir2str(di->data, di->kv.id, 0)) );
	  Swig_Append( value, Swig_Int(di->kv.num) );
	  Swig_Append( value, Swig_Int(di->kv.num2) );
	}
	else
	  fprintf(stderr, "REPOKEY_TYPE_DIRNUMNUMARRAY: without repodata\n");
      break;
      case REPOKEY_TYPE_MD5:
      case REPOKEY_TYPE_SHA1:
      case REPOKEY_TYPE_SHA256:
	if (di->data)
	  value = Swig_String( repodata_chk2str(di->data, di->key->type, (unsigned char *)di->kv.str) );
	else
	  fprintf(stderr, "REPOKEY_TYPE_{MD5,SHA1,SHA256}: without repodata\n");
      break;
      case REPOKEY_TYPE_FIXARRAY:
      case REPOKEY_TYPE_FLEXARRAY:
	value = Swig_String( di->kv.eof == 0 ? "element" : "sentinel" );
      break;
      default:
        fprintf(stderr, "Unhandled type %d\n", di->key->type);
    }
  return value;
}

#endif /* GENERIC_HELPERS_H */
