/*-------------------------------------------------------------*/
/* Pool

Document-class: Pool
The pool contains information about solvables
stored optimized for memory consumption and fast retrieval.

Solvables represent (RPM) packages and are grouped in repositories.

Solving of dependencies works on the pool, usually with a
distinguished repository of installed solvables.

*/

%{
/*
 * callback for loading additional .solv files
 *  (aka 'attribute' files, referenced from within the main .solv file)
 */

static FILE *
poolloadcallback( Pool *pool, Repodata *data, void *vdata )
{
  FILE *fp = 0;
  const char *location = repodata_lookup_str(data, SOLVID_META, REPOSITORY_LOCATION);
  if (location) {
    fp = fopen(location, "r");
    if (!fp)
      fprintf( stderr, "*** failed reading %s\n", location );
  }
  return fp;
}


/*
 * namespace callback
 *
 * called by solver to compute language or hardware supplements
 *
 * name:    the namespace identifier, e.g. NAMESPACE_MODALIAS, NAMESPACE_LANGUAGE, NAMESPACE_FILESYSTEM, NAMESPACE_PRODUCTBUDDY
 * value    the value, e.g. pci:v0000104Cd0000840[01]sv*sd*bc*sc*i*
 * return: 0 if not supportded
 *         1 if supported by the system
 *         -1  AFAIK it's also possible to return a list of solvables that support it, but don't know how.
 */
 
static Id
poolnscallback(Pool *pool, void *data, Id name, Id value)
{
  Id id = 0;
  switch(name) {
    case NAMESPACE_MODALIAS:
    break;
    case NAMESPACE_LANGUAGE:
      id = (str2id(pool, "en", 1) == value);
    break;
    case NAMESPACE_FILESYSTEM:
    break;
    case NAMESPACE_PRODUCTBUDDY:
    break;
  }
  return id;
}


%}

%nodefault _Pool;
typedef struct _Pool {} Pool;
%rename(Pool) _Pool;

#if defined(SWIGRUBY)
%mixin Pool "Enumerable";
#endif

%extend Pool {

  /*
   * Document-method: new
   * Pool creation, optionally with an architecture
   * If you don't pass the architecture to the Pool constructor, you
   * can also use pool.arch= later.
   * call-seq:
   *  Pool.new -> Pool
   *  Pool.new("x86_64") -> Pool
   *
   */
  Pool( const char *arch = NULL )
  {
    Pool *pool = pool_create();
  
    if (arch) pool_setarch( pool, arch );
    pool_setloadcallback( pool, poolloadcallback, 0 );
    pool->nscallback = poolnscallback;
    pool->nscallbackdata = NULL;
    
    return pool;
  }

  /*
   * Pool destructor
   *
   * Implemented as no-op, see 'discard' for details.
   *
   */

  ~Pool()
  { }

  /*
   * Document-method: discard
   *
   * There is no destructor defined for Pool since the pool pointer
   * is mostly used implicitly (e.g. in Solvable or Solver) which
   * cannot be reliably tracked in the bindings.
   *
   * Deleting the Pool is seldomly needed anyways. Just call
   * Pool::discard to explicitly free the pool. Just remember that
   * Solvables originating from this Pool are invalidated.
   */
   
  void discard()
  { pool_free($self); }

  /*
   * Document-method: solvable
   * Access Solvable storage within the pool
   * Get solvable based on id from pool
   *
   * call-seq:
   *   pool.solvable(id) -> Solvable
   *
   */
  XSolvable *solvable(int id)
  {
    return xsolvable_new( $self, (Id)id);
  }
  
  /*
   * Document-method: relation
   * Access Solvable storage within the pool
   * Get relation based on id from Pool
   *
   * call-seq:
   *   pool.relation(id) -> Relation
   *
   */
  Relation *relation( int rel )
  { return relation_new( $self, (Id)rel ); }

#if defined(SWIGRUBY)
%{
  /*
   * Document-method: arch=
   * Defines the architecture of the pool. Only Solvables with a compatible
   * architecture will be considered.
   * Setting the architecture to "i686" is a good choice for most 32bit
   * systems, 64bit systems most probably need "x86_64"
   * Attn: There is no getter function for the architecture since
   * setting an architecture is converted to a list of 'compatible'
   * architectures internally. E.g. i686 is actually
   * i686,i586,i486,i386,noach. The solver will always choose the
   * 'best' architecture from this list.
   * call-seq:
   *  pool.arch = "i686"
   *
   */
%}
  %rename( "arch=" ) set_arch( const char *arch );
#endif
  void set_arch( const char *arch )
  { pool_setarch( $self, arch ); }

#if defined(SWIGRUBY)
  /*
   * Document-method: debug=
   * Increase verbosity on stderr
   *
   * call-seq:
   *  pool.debug = 1
   *
   */
  %rename( "debug=" ) set_debug( int level );
#endif
  %feature("autodoc", "Makes the stuff noisy on stderr.") set_debug;
  void set_debug( int level )
  { pool_setdebuglevel( $self, level ); }

  /*
   * Document-method: promoteepoch
   * If epoch should be promoted
   *
   */
  int promoteepoch()
  { return $self->promoteepoch; }
#if defined(SWIGRUBY)
  /*
   * Document-method: promoteepoch=
   * If epoch should be promoted
   *
   */
  %rename( "promoteepoch=" ) set_promoteepoch( int b );
#endif
  void set_promoteepoch( int b )
  { $self->promoteepoch = b; }

  /*
   * Document-method:
   *
   */
  int unprepared()
  { return $self->whatprovides == NULL; }

  /*
   * Document-method:
   *
   */
  void prepare()
  { pool_createwhatprovides( $self ); }

  /*
   * Document-method:
   *
   * System solvable
   */
  XSolvable* system()
  {
    return xsolvable_new($self, SYSTEMSOLVABLE);
  }

  /**************************
   * Repo management
   */

  /*
   * Document-method:
   *
   */
  Repo *add_file( FILE *fp )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_solv( repo, fp );
    return repo;
  }

#if defined(SWIGRUBY)
  /*
   * Document-method:
   *
   */
  Repo *add_solv( VALUE name )
  {
    const char *fname;
    /* try string conversion if not already a string */
    name = StringValue( name );
    fname = StringValuePtr( name );
#else
  Repo *add_solv( const char *fname )
  {
#endif
    Repo *repo = repo_create( $self, NULL );
    FILE *fp = fopen( fname, "r");
    if (fp) {
      repo_add_solv( repo, fp );
      fclose( fp );
    }
    return repo;
  }

  /*
   * Document-method:
   *
   */
  Repo *add_rpmdb( const char *rootdir )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_rpmdb( repo, NULL, rootdir, 0 );
    return repo;
  }

  /*
   * Document-method:
   *
   */
  Repo *create_repo( const char *name )
  { return repo_create( $self, name ); }

  /*
   * Document-method:
   *
   */
  int count_repos()
  { return $self->nrepos; }

  /*
   * Document-method:
   *
   */
  Repo *get_repo( int i )
  {
    if ( i < 0 ) return NULL;
    if ( i >= $self->nrepos ) return NULL;
    return $self->repos[i];
  }

#if defined(SWIGRUBY)
  /*
   * Document-method:
   *
   */
  void each_repo()
  {
    int i;
    for (i = 0; i < $self->nrepos; ++i )
      rb_yield(SWIG_NewPointerObj((void*) $self->repos[i], SWIGTYPE_p__Repo, 0));
  }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def repos(self):
          r = range(0,self.count_repos())
          while r:
            yield self.get_repo(r.pop(0))
    %}
#endif

  /*
   * Document-method:
   *
   */
  Repo *find_repo( const char *name )
  {
    int i;
    for (i = 0; i < $self->nrepos; ++i ) {
      if (!strcmp( $self->repos[i]->name, name ))
        return $self->repos[i];
    }
    return NULL;
  }

  /**************************
   * Relation management
   */

  /*
   * Document-method:
   *
   */
  Relation *create_relation( const char *name, int op = 0, const char *evr = NULL )
  {
    if (op && !evr)
      SWIG_exception( SWIG_NullReferenceError, "Relation operator with NULL evr" );
    return relation_create( $self, name, op, evr );
#if defined(SWIGPYTHON) || defined(SWIGPERL)
    fail:
#endif
    return NULL;
  }

  /*
   * Ruby has real iterators and callbacks, which make iterating over
   * providers (of name or relation) straightforward.
   * 
   * Other languages have to revert to providers_count and
   * providers_get and implement iterators themselves
   */

#if defined(SWIGRUBY)
   
  /*
   * Document-method: each_provider(Relation)
   * iterate over all providers of a relation
   * call-seq:
   *  pool.each_provider(relation) { |solvable| ... }
   *
   */
  void each_provider( Relation *rel )
  {
    Id p, pp;
    Pool *pool = $self;
    if (!$self->whatprovides)
      pool_createwhatprovides( $self );

    FOR_PROVIDES(p, pp, rel->id) {
      generic_xsolvables_iterate_callback( xsolvable_new( $self, p ), NULL );
    }
  }

  /*
   * Document-method: each_provider(string)
   * iterate over all providers of a string
   * call-seq:
   *  pool.each_provider("glibc") { |solvable| ... }
   *  pool.each_provider("/usr/bin/bash") { |solvable| ... }
   *
   */
  void each_provider( const char *name )
  {
    Id p, pp;
    Pool *pool = $self;
    if (!$self->whatprovides)
      pool_createwhatprovides($self);

    FOR_PROVIDES(p, pp, str2id( $self, name, 0) ) {
      generic_xsolvables_iterate_callback( xsolvable_new( $self, p ), NULL );
    }
  }

  /*
   * Document-method: each_provider(id)
   * iterater over all providers of a specific id
   * INTERNAL
   *
   */
  void each_provider( int id )
  {
    if (id > 0 && id < $self->whatprovidesdataoff) {
      while ($self->whatprovidesdata[id]) {
        generic_xsolvables_iterate_callback( xsolvable_new( $self, $self->whatprovidesdata[id++] ), NULL );
      }
    }
  }

#endif

#if defined(SWIGPERL)
  %perlcode %{
    sub providers {
      my ($self, $rel) = @_;
      my @prov = ();
      
      if ($self->unprepared()) {
        $self->prepare();
      }
      
      my $count = $self->providers_count($rel);
      for (my $i = 0; $i < $count; ++$i) {
        my $solvable = $self->providers_get($rel, $i);
        push @prov, $solvable;
      }

      return wantarray ? @prov : $prov[0];
    }
  %}
#endif

  /*
   * Document-method:
   *
   */
  int providers_count( const char *name )
  { int i = 0;
    Id v, *vp;
    for (vp = pool_whatprovides_ptr($self, str2id( $self, name, 0)) ; (v = *vp++) != 0; )
      ++i;
    return i;
  }

  /*
   * Document-method:
   *
   */
  int providers_count( Relation *rel )
  { int i = 0;
    Id v, *vp;
    for (vp = pool_whatprovides_ptr($self, rel->id) ; (v = *vp++) != 0; )
      ++i;
    return i;
  }

  /*
   * Document-method:
   *
   */
  XSolvable *providers_get( const char *name, int i)
  { Id *vp;
    vp = pool_whatprovides_ptr($self, str2id( $self, name, 0));
    return xsolvable_new( $self, *(vp + i));
  }
 
  /*
   * Document-method:
   *
   */
  XSolvable *providers_get( Relation *rel, int i)
  { Id *vp;
    vp = pool_whatprovides_ptr($self, rel->id);
    return xsolvable_new( $self, *(vp + i));
  }
  
  /*
   * providers iterator for Python
   * using providers_count and providers_get
   */
#if defined(SWIGPYTHON)
    %pythoncode %{
        def providers(self,what):
          if self.unprepared():
            self.prepare()
          r = range(0,self.providers_count(what))
          while r:
            yield self.providers_get(what, r.pop(0))
    %}
#endif

  /*
   * Solvable management
   */

  /*
   * Document-method:
   *
   *
   * number of solvables in pool
   */
  int size()
  { /* skip Ids 0(reserved) and 1(system) */
    return $self->nsolvables - 1 - 1;
  }

#if defined(SWIGRUBY)
  /*
   * Document-method: installable?
   * Find out if a solvable is installable (all its dependencies can
   * be satisfied)
   * call-seq:
   *  pool.installable?(Solvable) -> true
   *
   */
  %rename( "installable?" ) installable( XSolvable *s );
  %typemap(out) int installable
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int installable( XSolvable *s )
  { return pool_installable( $self, pool_id2solvable( s->pool, s->id ) ); }

  /*
   * Document-method: count
   * Return number of solvables in the pool
   *
   * call-seq:
   *  pool.count -> int
   *
   */
  int count()
  { return pool_xsolvables_count( $self ); }

#if defined(SWIGRUBY)
  /*
   * Document-method: each
   * Iterate over all solvables in the pool
   *
   * call-seq:
   *   pool.each { |solvable| ... }
   *
   */
  void each()
  { pool_xsolvables_iterate( $self, generic_xsolvables_iterate_callback, NULL ); }
#endif

/* Nah, thats not for Ruby. Use Repo#each in Ruby */
#if !defined(SWIGRUBY)
  XSolvable **solvables() {
    int count = pool_xsolvables_count( $self );
    Solvable *s;
    Id p;
    int i = 0;
    XSolvable **xs = (XSolvable **) malloc((count + 1) * sizeof(XSolvable **));

    for (p = 2, s = $self->solvables + p; p < $self->nsolvables; p++, s++)
      {
        if (!s)
          continue;
        if (!s->name)
          continue;
        xs[i] = xsolvable_new($self, s - $self->solvables);
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
   * Document-method:
   *
   */
  XSolvable *find( char *name, Repo *repo = NULL )
  { return xsolvable_find( $self, name, repo ); }

  /*
   * Dataiterator - find solvables by their attributes
   */
#if defined(SWIGPYTHON)
    %pythoncode %{
        def search(self, match, flags, solvable = None, keyname = None):
          d = Dataiterator(self, None, match, flags, solvable, keyname)
          while d.step():
            yield d
    %}
#endif

#if defined(SWIGRUBY)
  /*
   * Document-method:
   *
   */
  void search(const char *match, int flags, XSolvable *xs = NULL, const char *keyname = NULL) 
  {
    Dataiterator *di;
    di = swig_dataiterator_new($self, NULL, match, flags, xs, keyname);
    while( dataiterator_step(di) ) {
      rb_yield(SWIG_NewPointerObj((void*) di, SWIGTYPE_p__Dataiterator, 0));
    }
    swig_dataiterator_free(di);
  }
#endif

  /**************************
   * Transaction management
   */

  /*
   * Document-method:
   *
   */
  Transaction *create_transaction()
  { return transaction_new( $self ); }

  /**************************
   * Solver management
   */

#if defined(SWIGRUBY)
  /*
   * Document-method: installed=
   * Set the repository representing the installed solvables
   * call-seq:
   *  pool.installed = repository
   *
   */
  %rename( "installed=" ) set_installed( Repo *repo );
#endif
  void set_installed(Repo *installed = NULL)
  {
    pool_set_installed( $self, installed);
  }
  
  /*
   * Document-method: installed
   * Return the repository representing the installed solvables.
   * Returns nil if installed= was not called before.
   * call-seq:
   *  pool.installed -> repository
   *
   */
  Repo *installed()
  {
    return $self->installed;
  }

  /*
   * Document-method: create_solver
   * Create a solver for this pool
   * call-seq:
   *  pool.create_solver -> Solver
   *
   */
  Solver* create_solver()
  {
    pool_createwhatprovides( $self );
    return solver_create( $self );
  }

}

