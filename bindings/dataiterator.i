/*
 * Dataiterator
 */

%nodefault _Dataiterator;
%rename(Dataiterator) _Dataiterator;
typedef struct _Dataiterator {} Dataiterator;


%extend Dataiterator {
  %constant int SEARCH_STRINGMASK = SEARCH_STRINGMASK;
  %constant int SEARCH_STRING = SEARCH_STRING;
  %constant int SEARCH_SUBSTRING = SEARCH_SUBSTRING;
  %constant int SEARCH_GLOB = SEARCH_GLOB;
  %constant int SEARCH_REGEX = SEARCH_REGEX;
  %constant int SEARCH_ERROR = SEARCH_ERROR;

  %constant int SEARCH_NOCASE = SEARCH_NOCASE;
  %constant int SEARCH_NO_STORAGE_SOLVABLE = SEARCH_NO_STORAGE_SOLVABLE;
  %constant int SEARCH_SUB = SEARCH_SUB;
  %constant int SEARCH_ARRAYSENTINEL = SEARCH_ARRAYSENTINEL;
  %constant int SEARCH_SKIP_KIND = SEARCH_SKIP_KIND;

/* By default we don't match in attributes representing filelists
   because the construction of those strings is costly.  Specify this
   flag if you want this.  In that case kv->str will contain the full
   filename (if matched of course).  */
  %constant int SEARCH_FILES = SEARCH_FILES;

  /*
   * Complete Dataiterator constructor, to be used via %python in Swig
   */

  Dataiterator(Repo *repo, const char *match, int option, XSolvable *xs = 0, const char *keyname = 0)
  {
    Dataiterator *di = calloc(1, sizeof( Dataiterator ));
    Solvable *s = 0;
    if (xs) s = xsolvable_solvable(xs);
    dataiterator_init(di, repo->pool, repo, s ? s - repo->pool->solvables : 0, keyname ? str2id(repo->pool, keyname, 0) : 0, match, option);
    return di;
  }
  
  ~Dataiterator() { dataiterator_free($self); free( $self ); }

  XSolvable *solvable()
  {
    return xsolvable_new( $self->repo->pool, $self->solvid );
  }

  /*
   * return corresponding Repokey, if defined
   * internal attributes, like solvable.name, don't have an
   * explicit Repokey
   */
  XRepokey *key()
  {
    return xrepokey_new($self->key, $self->repo, $self->data);
  }

  const char *keyname()
  {
    return id2str($self->repo->pool, $self->key->name);
  }

#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPERL)
  SV *
#endif
    value()
  {
    Swig_Type value = dataiterator_value($self);
#if defined(SWIGPYTHON)
    Py_INCREF(value);
#endif
    return value;
  }
  
  int step()
  {
    return dataiterator_step( $self );
  }
  
  void skip_attr()
  {
    dataiterator_skip_attribute($self);
  }
  
  void skip_solvable()
  {
    dataiterator_skip_solvable($self);
  }
  
  void skip_repo()
  {
    dataiterator_skip_repo($self);
  }
  
  void jump_to_solvable(XSolvable *xs)
  {
    dataiterator_jump_to_solvid($self, xs->id);
  }
  
  void jump_to_repo(Repo *repo)
  {
    dataiterator_jump_to_repo($self, repo);
  }
}

