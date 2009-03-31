/*
 * Document-class: Repo
 * The Repo represents a Set of Solvables from the same origin. This
 * is usually a .+solv+ file (e.g. create from a package Repository) or the RPM database.
 *
 * Repositories can be given a name, making it easier to identify and
 * reference them.
 *
 * === About memory management
 *
 * Since Solvables  _back_ _reference_ the Repo they belong to, the Repo
 * desctructor is left as a no-op. In the rare case that one has to free memory
 * allocated to a Repo, call +discard+ and do not reference any
 * Solvables originating from this Repo.
 *
 */

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

#if defined(SWIGRUBY)
%mixin Repo "Enumerable";
#endif

%extend Repo {
  /*
   * Document-method: new
   * Create a new Repository in Pool with a given name
   *
   * See also: Pool.create_repo()
   *
   * call-seq:
   *   Repo.new(pool, "test")
   *
   */
  Repo( Pool *pool, const char *reponame )
  { return repo_create( pool, reponame ); }
  ~Repo()
  { }

  /*
   * Discard Repo
   */
  void discard()
  { repo_free( $self, 1 ); }

#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  /*
   * A string representation
   */
  const char *string()
  {
    return $self->name;
  }

  /*
   * see also count() below !
   */
  int size()
  { return $self->nsolvables; }
#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  /*
   * Returns +true+ if there are no Solvables in this Repo
   */
  int empty()
  { return $self->nsolvables == 0; }

  /*
   * The name of the Repo
   */
  const char *name()
  { return $self->name; }
#if defined(SWIGRUBY)
  %rename( "name=" ) set_name( const char *name );
#endif
  /*
   * Assign a name to the Repo
   */
  void set_name( const char *name )
  { if ($self->name)
      sat_free((char *)$self->name);
    $self->name = strdup(name);
  }

  /*
   * The priority of this Repo
   */
  int priority()
  { return $self->priority; }
#if defined(SWIGRUBY)
  %rename( "priority=" ) set_priority( int i );
#endif
  void set_priority( int i )
  { $self->priority = i; }

  /*
   * The Pool this Repo belongs to
   */
  Pool *pool()
  { return $self->pool; }

  /*
   * Add opened .+solv+ file to Repo
   */
  void add_file( FILE *fp )
  { repo_add_solv( $self, fp ); }

#if defined(SWIGRUBY)
  /*
   * :nodoc:
   */
  void add_solv( VALUE name )
  {
    const char *fname;
    /* try string conversion if not already a string */
    name = StringValue( name );
    fname = StringValuePtr( name );
#else
  /*
   * Add .+solv+ file by name
   */
  void add_solv( const char *fname )
  {
#endif
    FILE *fp = fopen( fname, "r");
    if (fp) {
      repo_add_solv( $self, fp );
      fclose( fp );
    }
  }

  /*
   * Add RPM database, optionally passing a _root_ directory
   */
  void add_rpmdb( const char *rootdir )
  { repo_add_rpmdb( $self, NULL, rootdir, 0); }

  /*
   * Create solvable with +name+ and +evr+ in the Repo
   * Can optionally be passed an architecture, defaulting to +noarch+
   *
   * call-seq:
   *   repo.create_solvable("test", "42.0-1")
   *   repo.create_solvable("foo", "1.2-3", "x86_64")
   *
   */
  XSolvable *create_solvable( const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( $self, name, evr, arch ); }

#if defined(SWIGRUBY)
  %alias add "<<";
#endif
  /*
   * Add Solvable to Repo
   */
  XSolvable *add( XSolvable *xs )
  { return xsolvable_add( $self, xs ); }

#if defined(SWIGRUBY)
  /*
   * Iterator for all Solvables
   *
   * call-seq:
   *   repo.each { |solvable| ... }
   *
   */
  void each()
  { repo_xsolvables_iterate( $self, generic_xsolvables_iterate_callback, NULL ); }
#endif
  /*
   * Number of Solvables in Repo
   *
   */
  int count()
  { return repo_xsolvables_count( $self ); }

/* Nah, thats not for Ruby. Use Repo#each in Ruby */
#if !defined(SWIGRUBY)
  /*
   * :nodoc:
   */
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

  /*
   * return number of attached Repodata(s)
   */
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

#if defined(SWIGPYTHON)
  /*
   * Dataiterator - find solvables by their attributes
   */
    %pythoncode %{
        def search(self, match, flags, solvable = None, keyname = None):
          d = Dataiterator(self.pool(), self, match, flags, solvable, keyname)
          while d.step():
            yield d
    %}
#endif

#if defined(SWIGRUBY)
  /*
   * Search for Solvable attributes in Repository
   *
   * See +Dataiterator+ for example code
   *
   * call-seq:
   *  repo.search("match", flags) { |dataiterator| ... }
   *  repo.search("match", flags, solvable) { |dataiterator| ... }
   *  repo.search("match", flags, solvable, key) { |dataiterator| ... }
   *
   */
  void search(const char *match, int flags, XSolvable *xs = NULL, const char *keyname = NULL) 
  {
    Dataiterator *di;
    di = swig_dataiterator_new($self->pool, $self, match, flags, xs, keyname);
    while( dataiterator_step(di) ) {
      rb_yield(SWIG_NewPointerObj((void*) di, SWIGTYPE_p__Dataiterator, 0));
    }
    swig_dataiterator_free(di);
  }
#endif

  /*
   * access attribute via []
   */

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias attr "[]";
  /*
   * Attribute accessor.
   *
   * It takes either a string or a symbol and returns
   * the value of the attribute.
   *
   * If its a symbol, all underline characters are converted
   * to colons. E.g. +:solvable_installsize+ -> +"solvable:installsize"+
   *
   * A +ValueError+ exception is raised if the attribute
   * name does not exist.
   *
   * +nil+ is returned if the attribute name exists but is not set for
   * the solvable.
   *
   *
   * call-seq:
   *  repo["repository:timestamp"] -> VALUE
   *  repo.attr("repository:timestamp") -> VALUE
   *  repo.attr(:repository_timestamp) -> VALUE
   *
   */
  VALUE attr( VALUE attrname )
  {
#endif
#if defined(SWIGPYTHON)
  PyObject *attr( const char *name )
  {
#endif
#if defined(SWIGPERL)
  SV *attr( const char *name )
  {
#endif
    Swig_Type result = Swig_Null;
    Id key;
    Dataiterator di;
#if defined(SWIGRUBY)
    char *name;

    if (SYMBOL_P(attrname)) {
      char *colon;
      name = (char *)rb_id2name( SYM2ID( attrname ) );
      colon = name;
      while ((colon = strchr( colon, '_'))) {
        *colon++ = ':';
      }
    }
    else
      name = StringValuePtr( attrname );
#endif
    if (!name)
      SWIG_exception( SWIG_ValueError, "Attribute name missing" );

    /* key existing in pool ? */
    key = str2id( $self->pool, name, 0);
    if (key == ID_NULL)
      SWIG_exception( SWIG_ValueError, "No such attribute name" );

    dataiterator_init(&di, $self->pool, $self, SOLVID_META, key, 0, 0);
    if (dataiterator_step(&di))
    {
      result = dataiterator_value( &di );
    }

#if defined(SWIGPYTHON) || defined(SWIGPERL)/* needed for SWIG_Exception */
fail:
#endif
#if defined(SWIGPYTHON)
    Py_INCREF(result);
#endif
    return result;
  }


}
