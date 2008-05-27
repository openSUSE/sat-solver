/*
 * Repo
 */

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;


%extend Repo {
  Repo( Pool *pool, const char *reponame )
  { return repo_create( pool, reponame ); }

  int size()
  { return $self->nsolvables; }
#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int empty()
  { return $self->nsolvables == 0; }

  const char *name()
  { return $self->name; }
#if defined(SWIGRUBY)
  %rename( "name=" ) set_name( const char *name );
#endif
  void set_name( const char *name )
  { $self->name = name; }
  int priority()
  { return $self->priority; }
#if defined(SWIGRUBY)
  %rename( "priority=" ) set_priority( int i );
#endif
  void set_priority( int i )
  { $self->priority = i; }
  Pool *pool()
  { return $self->pool; }

  void add_file( FILE *fp )
  { repo_add_solv( $self, fp ); }

  void add_solv( const char *fname )
  {
    FILE *fp = fopen( fname, "r");
    if (fp) {
      repo_add_solv( $self, fp );
      fclose( fp );
    }
  }

  void add_rpmdb( const char *rootdir )
  { repo_add_rpmdb( $self, NULL, rootdir ); }

  XSolvable *create_solvable( const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( $self, name, evr, arch ); }

#if defined(SWIGRUBY)
  %alias add "<<";
#endif
  XSolvable *add( XSolvable *xs )
  { return xsolvable_add( $self, xs ); }

  void each()
  { repo_xsolvables_iterate( $self, generic_xsolvables_iterate_callback ); }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  /*
   * get xsolvable by index
   */
  XSolvable *get( int i )
  { return xsolvable_get( $self->pool, i, $self ); }

  /*
   * find (best) solvable by name
   */
  XSolvable *find( char *name )
  { return xsolvable_find( $self->pool, name, $self ); }

  /*-----
   * Repodata / Attributes
   */

  /* return number of attached Repodata(s) */
  int datasize()
  { return $self->nrepodata; }

  /*
   * get Repodata by index
   */
  Repodata *data( int i )
  {
    if (i >= 0 && i < $self->nrepodata)
      return $self->repodata + i;
    return NULL;
  }

#if defined(SWIGRUBY)
  /*
   * Iterate over each Repodata
   */
  void each_data()
  {
    int i;
    for (i = 0; i < $self->nrepodata; ++i ) {
      rb_yield( SWIG_NewPointerObj((void*) $self->repodata + i, SWIGTYPE_p__Repodata, 0) );
    }
  }
#endif
}

