/*
 * Repo
 */

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

#if defined(SWIGRUBY)
%mixin Repo "Enumerable";
#endif

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
  /* see also count() below ! */
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
  { repo_add_rpmdb( $self, NULL, rootdir, 0); }

  XSolvable *create_solvable( const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( $self, name, evr, arch ); }

#if defined(SWIGRUBY)
  %alias add "<<";
#endif
  XSolvable *add( XSolvable *xs )
  { return xsolvable_add( $self, xs ); }

#if defined(SWIGRUBY)
  void each()
  { repo_xsolvables_iterate( $self, generic_xsolvables_iterate_callback, NULL ); }
#endif
  int count()
  { return repo_xsolvables_count( $self ); }

/* Nah, thats not for Ruby. Use Repo#each in Ruby */
#if !defined(SWIGRUBY)
  XSolvable **solvables() {
    int count = repo_xsolvables_count( $self );
    Id p;
    Solvable *s;
    int i = 0;
    XSolvable **xs = (XSolvable **) malloc((count + 1) * sizeof(XSolvable **));

    FOR_REPO_SOLVABLES($self, p, s)
      {
        if (!s)
          continue;
        if (!s->name)
          continue;
        xs[i] = xsolvable_new($self->pool, s - $self->pool->solvables);
        ++i;
      }
    xs[i] = NULL;

    return xs;
  }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def __iter__(self):
          s = self.solvables()
          while s:
            yield s.pop(0)
    %}
#endif

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

  /*
   * Dataiterator - find solvables by their attributes
   */
#if defined(SWIGPYTHON)
    %pythoncode %{
        def search(self, match, flags, solvable = None, keyname = None):
          d = Dataiterator(self.pool(), self, match, flags, solvable, keyname)
          while d.step():
            yield d
    %}
#endif
}

