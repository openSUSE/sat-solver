/*
 * XRepokey
 */

%nodefault _Repokey;
%rename(Repokey) _Repokey;
typedef struct _Repokey {} XRepokey; /* expose XRepokey as 'Repokey' */

%extend XRepokey {
  /* no explicit constructor, Repokey is embedded in Repodata */

  ~XRepokey()
  { xrepokey_free( $self ); }
  
  /* name of key */
  const char *name()
  {
    Repokey *key = xrepokey_repokey( $self );
    return my_id2str( $self->repodata->repo->pool, key->name );
  }
  /* type of key */
#if defined(SWIGRUBY)
  VALUE type()
  {
    Repokey *key = xrepokey_repokey( $self );
    VALUE type = Qnil;
    switch( key->type )
    {
      case REPOKEY_TYPE_VOID: type = rb_cTrueClass; break;
      case REPOKEY_TYPE_CONSTANTID: type = rb_cString; break;
      case REPOKEY_TYPE_CONSTANT: type = rb_cInteger; break;
      case REPOKEY_TYPE_ID: type = rb_cString; break;
      case REPOKEY_TYPE_IDARRAY: type = rb_cArray; break;
      case REPOKEY_TYPE_STR: type = rb_cString; break;
      case REPOKEY_TYPE_U32: type = rb_cInteger; break;
      case REPOKEY_TYPE_REL_IDARRAY: type = rb_cArray; break;
      case REPOKEY_TYPE_DIR: type = rb_cDir; break;
      case REPOKEY_TYPE_DIRNUMNUMARRAY: type = rb_cArray; break;
      case REPOKEY_TYPE_DIRSTRARRAY: type = rb_cArray; break;
      case REPOKEY_TYPE_NUM: type = rb_cNumeric; break;
    }
    return type;
  }
#else
  int type()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->type;
  }
#endif
  /* size of key */
  int size()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->size;
  }
}

