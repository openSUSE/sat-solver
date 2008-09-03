/*
 * Repo
 */

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;


%extend Repo {
  Repo( Pool *pool, const char *reponame )
  { return repo_create( pool, reponame ); }
  ~Repo()
  { }
  void remove()
  { repo_free( $self, 1 ); }

#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  const char *string()
  {
    return $self->name;
  }

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
  { if ($self->name)
      sat_free((char *)$self->name);
    $self->name = strdup(name);
  }
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

#if defined(SWIGRUBY)
  void add_solv( VALUE name )
  {
    const char *fname;
    /* try string conversion if not already a string */
    name = rb_check_convert_type( name, T_STRING, "String", "to_s" );
    fname = StringValuePtr( name );
#else
  void add_solv( const char *fname )
  {
#endif
    FILE *fp = fopen( fname, "r");
    if (fp) {
      repo_add_solv( $self, fp );
      fclose( fp );
    }
  }

  void add_rpmdb( const char *rootdir )
  { repo_add_rpmdb( $self, NULL, NULL, rootdir ); }

  XSolvable *create_solvable( const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( $self, name, evr, arch ); }

#if defined(SWIGRUBY)
  %alias add "<<";
#endif
  XSolvable *add( XSolvable *xs )
  { return xsolvable_add( $self, xs ); }

#if defined(SWIGRUBY)
  void each()
  { repo_xsolvables_iterate( $self, generic_xsolvables_iterate_callback ); }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def __iter__(self):
          r = range(0,self.size())
          while r:
            yield self.get(r.pop(0))
    %}
#endif

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
#if defined(SWIGPYTHON)
    %pythoncode %{
        def datas(self):
          r = range(0,self.datasize())
          while r:
            yield self.data(r.pop(0))
    %}
#endif
}

