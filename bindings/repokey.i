/*
 * Document-class: Repokey
 * Repokey is the Key part of the key/value pair describing an attribute
 *
 */

%nodefault _Repokey;
%rename(Repokey) _Repokey;
typedef struct _Repokey {} XRepokey; /* expose XRepokey as 'Repokey' */

%extend XRepokey {

%constant int REPOKEY_TYPE_VOID = REPOKEY_TYPE_VOID;
%constant int REPOKEY_TYPE_CONSTANT = REPOKEY_TYPE_CONSTANT;
%constant int REPOKEY_TYPE_CONSTANTID = REPOKEY_TYPE_CONSTANTID;
%constant int REPOKEY_TYPE_ID = REPOKEY_TYPE_ID;
%constant int REPOKEY_TYPE_NUM = REPOKEY_TYPE_NUM;
%constant int REPOKEY_TYPE_U32 = REPOKEY_TYPE_U32;
%constant int REPOKEY_TYPE_DIR = REPOKEY_TYPE_DIR;
%constant int REPOKEY_TYPE_STR = REPOKEY_TYPE_STR;
%constant int REPOKEY_TYPE_IDARRAY = REPOKEY_TYPE_IDARRAY;
%constant int REPOKEY_TYPE_REL_IDARRAY = REPOKEY_TYPE_REL_IDARRAY;
%constant int REPOKEY_TYPE_DIRSTRARRAY = REPOKEY_TYPE_DIRSTRARRAY;
%constant int REPOKEY_TYPE_DIRNUMNUMARRAY = REPOKEY_TYPE_DIRNUMNUMARRAY;
%constant int REPOKEY_TYPE_MD5 = REPOKEY_TYPE_MD5;
%constant int REPOKEY_TYPE_SHA1 = REPOKEY_TYPE_SHA1;
%constant int REPOKEY_TYPE_SHA256 = REPOKEY_TYPE_SHA256;
%constant int REPOKEY_TYPE_FIXARRAY = REPOKEY_TYPE_FIXARRAY;
%constant int REPOKEY_TYPE_FLEXARRAY = REPOKEY_TYPE_FLEXARRAY;

  /* no explicit constructor, Repokey is embedded in Repodata */

  ~XRepokey()
  { xrepokey_free( $self ); }
  
  /*
   * name of key
   */
  const char *name()
  {
    Repokey *key = xrepokey_repokey( $self );
    return my_id2str( $self->repo->pool, key->name );
  }

  /*
   * type id of key
   * 
   * One of +Satsolver::REPOKEY_TYPE_*+
   */
  int type_id()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->type;
  }
  
  /*
   * Class of key
   *
   * Returns a _best_ _matching_ Class representation of the type
   *
   * i.e. +Satsolver::REPOKEY_TYPE_VOID+ is represented as a +Boolean+ since presence of the key means +true+ for this attribute.
   *
   */
#if defined(SWIGPYTHON)
PyTypeObject *
#endif
#if defined(SWIGRUBY)
VALUE
#endif
#if defined(SWIGPERL)
SV *
#endif
    type()
  {
    Repokey *key = xrepokey_repokey( $self );
    Swig_Type_Type type = Swig_Type_Null;
    switch( key->type )
    {
      case REPOKEY_TYPE_VOID:
        type = Swig_Type_Bool;
	break;
      case REPOKEY_TYPE_CONSTANTID:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_CONSTANT:
        type = Swig_Type_Int;
	break;
      case REPOKEY_TYPE_ID:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_IDARRAY:
        type = Swig_Type_Array;
	break;
      case REPOKEY_TYPE_STR:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_U32:
        type = Swig_Type_Int;
	break;
      case REPOKEY_TYPE_REL_IDARRAY:
        type = Swig_Type_Array;
	break;
      case REPOKEY_TYPE_DIR:
        type = Swig_Type_Directory;
	break;
      case REPOKEY_TYPE_DIRNUMNUMARRAY:
        type = Swig_Type_Array;
	break;
      case REPOKEY_TYPE_DIRSTRARRAY:
        type = Swig_Type_Array;
	break;
      case REPOKEY_TYPE_NUM:
        type = Swig_Type_Number;
	break;
      case REPOKEY_TYPE_MD5:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_SHA1:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_SHA256:
        type = Swig_Type_String;
	break;
      case REPOKEY_TYPE_FIXARRAY:
        type = Swig_Type_Number;
	break;
      case REPOKEY_TYPE_FLEXARRAY:
        type = Swig_Type_Number;
	break;
    }
    return type;
  }
  /*
   * size of key
   *
   * Internal memory consumption
   *
   */
  int size()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->size;
  }
#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  /*
   * String representation of the key
   */
  const char *string()
  {
    Repokey *key = xrepokey_repokey( $self );
    return my_id2str( $self->repo->pool, key->name );
  }
}

