/* 
 * Document-class: Pool
 * The Pool contains information about solvables
 * stored optimized for memory consumption and fast retrieval.
 * 
 * Solvables represent (RPM) packages and are grouped in repositories.
 * 
 * Solving of dependencies works on the Pool, usually with a
 * distinguished repository of installed solvables.
 * 
 * === About memory management
 * Pool should be a Singleton, there is no actual need to have multiple pools.
 *
 * Since a lot of objects _back_ _reference_ the Pool they belong to, the Pool
 * desctructor is left as a no-op. In the rare case that one has to free memory
 * allocated to a Pool, call +discard+ and do not reference any objects (Repo, Solvable, Solver, ...) originating from this Pool.
 *
 */

%{
/*
 * callback for loading additional .solv files
 *  (aka 'attribute' files, referenced from within the main .solv file)
 */

static int
poolloadcallback( Pool *pool, Repodata *data, void *vdata )
{
  FILE *fp;
  const char *location = repodata_lookup_str(data, SOLVID_META, REPOSITORY_LOCATION);
  int r;
  if (!location)
    return 0;
  fp = fopen(location, "r");
  if (!fp)
    {
      fprintf( stderr, "*** failed reading %s\n", location );
      return 0;
    }
  r = repo_add_solv_flags(data->repo, fp, REPO_USE_LOADING|REPO_LOCALPOOL);
  fclose(fp);
  return r ? 0 : 1;
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
   * Pool creation, optionally with an architecture
   *
   * If you don't pass the architecture to the Pool constructor, you
   * can also use pool.arch= later.
   *
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
   *
   */
   
  void discard()
  { pool_free($self); }

  /*
   * Access Solvable storage within the pool
   *
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
   * Access Solvable storage within the pool
   *
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
   * Defines the architecture of the pool.
   
   * Only Solvables with a compatible architecture will be considered.
   *
   * Setting the architecture to "i686" is a good choice for most 32bit
   * systems, 64bit systems most probably need "x86_64"
   * Attn: There is no getter function for the architecture since
   * setting an architecture is converted to a list of 'compatible'
   * architectures internally. E.g. i686 is actually
   * i686,i586,i486,i386,noach. The solver will always choose the
   * 'best' architecture from this list.
   *
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
   * If epoch should be promoted
   *
   */
  int promoteepoch()
  { return $self->promoteepoch; }
#if defined(SWIGRUBY)
  /*
   * If epoch should be promoted
   *
   */
  %rename( "promoteepoch=" ) set_promoteepoch( int b );
#endif
  void set_promoteepoch( int b )
  { $self->promoteepoch = b; }

#if defined(SWIGRUBY)
  %typemap(out) int no_virtual_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow virtual conflicts
   *
   * call-seq:
   *  pool.no_virtual_conflicts -> bool
   *
   */
  int no_virtual_conflicts()
  { return $self->novirtualconflicts; }

#if defined(SWIGRUBY)
  %rename( "no_virtual_conflicts=" ) set_no_virtual_conflicts( int bflag );
#endif
  /*
   * call-seq:
   *  pool.no_virtual_conflicts = true
   *
   */
  void set_no_virtual_conflicts( int bflag )
  { $self->novirtualconflicts = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_self_conflicts
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Allow self conflicts
   *
   * If a package can conflict with itself
   *
   * call-seq:
   *  pool.allow_self_conflicts -> bool
   *
   */
  int allow_self_conflicts()
  { return $self->allowselfconflicts; }

#if defined(SWIGRUBY)
  %rename( "allow_self_conflicts=" ) set_allow_self_conflicts( int bflag );
#endif
  /*
   * call-seq:
   *  pool.allow_self_conflicts = true
   *
   */
  void set_allow_self_conflicts( int bflag )
  { $self->allowselfconflicts = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Obsolete uses provides
   *
   * Obsolete dependencies usually match on package names only.
   * Setting this flag will make obsoletes also match a provides.
   *
   * call-seq:
   *  pool.obsolete_uses_provides -> bool
   *
   */
  int obsolete_uses_provides()
  { return $self->obsoleteusesprovides; }

#if defined(SWIGRUBY)
  %rename( "obsolete_uses_provides=" ) set_obsolete_uses_provides( int bflag );
#endif
  /*
   * Obsolete uses provides
   *
   * call-seq:
   *  pool.obsolete_uses_provides = true
   *
   */
  void set_obsolete_uses_provides( int bflag )
  { $self->obsoleteusesprovides= bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int implicit_obsolete_uses_provides
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Implicit obsolete uses provides
   *
   * call-seq:
   *  pool.implicit_obsolete_uses_provides -> bool
   *
   */
  int implicit_obsolete_uses_provides()
  { return $self->implicitobsoleteusesprovides; }

#if defined(SWIGRUBY)
  %rename( "implicit_obsolete_uses_provides=" ) set_implicit_obsolete_uses_provides( int bflag );
#endif
  /*
   * call-seq:
   *  pool.implicit_obsolete_uses_provides = true
   *
   */
  void set_implicit_obsolete_uses_provides( int bflag )
  { $self->implicitobsoleteusesprovides= bflag; }

  /*
   * Set the pool to an _unprepared_ status.
   * 
   * You must run Pool.prepare before using a solver on this Pool.
   * 
   * See also +Pool+.+prepare+
   *
   */
  int unprepared()
  { return $self->whatprovides == NULL; }

  /*
   * Prepare the pool for solving.
   *
   * After calling prepare, one must not
   * add or remove Repositories or add/remove Solvables within a Repository.
   *
   */
  void prepare()
  { pool_createwhatprovides( $self ); }

  /*
   * Get system solvable
   *
   * This is an internal solvable representing requirements of the
   * system where satsolver is running.
   *
   * call-seq:
   *  pool.system -> Solvable
   *
   */
  XSolvable* system()
  {
    return xsolvable_new($self, SYSTEMSOLVABLE);
  }

  /*
   * Pool equality
   */

#if defined(SWIGPERL)
  /*
   * :nodoc:
   */
  int __eq__( const Pool *pool )
#endif
#if defined(SWIGRUBY)
  %typemap(out) int equal
    "$result = $1 ? Qtrue : Qfalse;";
  %rename("==") equal;
  /*
   * Equality operator
   *
   */
  int equal( const Pool *pool )
#endif

#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   * Python treats 'eq' and 'ne' distinct.
   */
  int __ne__( const Pool *pool )
  { return $self != pool; }
  int __eq__( const Pool *pool )
#endif
  { return $self == pool; } /* common implementation */



  /**************************
   * Repo management
   */

  /*
   * Add opened .+solv+ file to pool.
   *
   * Returns newly created Repository
   *
   * call-seq:
   *   pool.add_file( File.open( "foo.solv" ) ) -> Repo
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
   * Add .+solv+ file to Pool
   *
   * Returns newly created Repository
   *
   * call-seq:
   *   pool.add_solv( "foo.solv" ) -> Repo
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
   * Add RPM database to Pool.
   *
   * For chrooted RPM databases, pass the toplevel directory as
   * parameter.
   *
   * Returns a newly created Repository
   *
   * call-seq:
   *   pool.add_rpmdb -> Repo
   *   pool.add_rpmdb("/space/chroot") -> Repo
   *
   */
  Repo *add_rpmdb( const char *rootdir )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_rpmdb( repo, NULL, rootdir, 0 );
    return repo;
  }

  %newobject create_repo;
  /*
   * Create an empty repository, optionally with a name.
   *
   * This repository should then be populated with Solvables.
   *
   * Equivalent to: Repo.new
   *
   * call-seq:
   *  pool.create_repo -> Repo
   *  pool.create_repo("test") -> Repo
   *
   */
  Repo *create_repo( const char *name = NULL )
  { return repo_create( $self, name ); }

  /*
   * Return the number of repositories in this pool
   *
   * call-seq:
   *  pool.count_repos -> int
   *
   */
  int count_repos()
  { return $self->nrepos; }

  /*
   * Get a repository by index from the pool.
   * Returns +nil+ if no such Repository exists.
   *
   * call-seq:
   *   pool.get_repo(2) -> Repo
   *   pool.get_repo(-42) -> nil
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
   * Interate through all Repositories of this Pool
   *
   * call-seq:
   *  pool.each_repo { |repo| ... }
   *
   */
  void each_repo()
  {
    Pool *pool = $self;
    Repo *r;
    int i;

    FOR_REPOS(i, r)
      rb_yield(SWIG_NewPointerObj((void*)r, SWIGTYPE_p__Repo, 0));
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
#if defined(SWIGPERL)
  const Repo **repos()
  {
    Pool *pool = $self;
    Repo *r;
    int i;
    PtrIndex pi;

    NewPtrIndex(pi,const Repo **,$self->nrepos);
    FOR_REPOS(i, r) {
      AddPtrIndex((&pi),const Repo **,r);
    }
    ReturnPtrIndex(pi,const Repo **);
  }
#endif

  /*
   * Find Repository by name. Returns +nil+ if no Repository with the
   * given name exists.
   *
   * call-seq:
   *  pool.find_repo("test") -> Repo
   *
   */
  Repo *find_repo( const char *name )
  {
    Pool *pool = $self;
    Repo *r;
    int i;

    FOR_REPOS(i, r)
      if (!strcmp(r->name, name))
        return r;
    return NULL;
  }

  /**************************
   * Relation management
   */

  %newobject create_relation;
  /*
   * Create a relation.
   *
   * Equivalent to: Relation.new
   *
   * call-seq:
   *  pool.create_relation( "kernel" ) -> Relation
   *  pool.create_relation( "kernel", REL_GE, "2.6.26" ) -> Relation
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
   * Iterate over all providers of a relation
   *
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
   * Iterate over all providers of a string
   *
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
   * Iterater over all providers of a specific id
   *
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
   * Count number of solvables providing _name_
   *
   * call-seq:
   *  pool.providers_count("kernel") { |solvable| ... }
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
   * Count number of solvables providing _relation_
   *
   * call-seq:
   *  pool.providers_count(relation) { |solvable| ... }
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
   * Return n'th provider providing _name_
   *
   * INTERNAL
   *
   */
  XSolvable *providers_get( const char *name, int i)
  { Id *vp;
    vp = pool_whatprovides_ptr($self, str2id( $self, name, 0));
    return xsolvable_new( $self, *(vp + i));
  }
 
  /*
   * Return n'th provider providing _relation_
   *
   * INTERNAL
   *
   */
  XSolvable *providers_get( Relation *rel, int i)
  { Id *vp;
    vp = pool_whatprovides_ptr($self, rel->id);
    return xsolvable_new( $self, *(vp + i));
  }
  
#if defined(SWIGPYTHON)
  /*
   * providers iterator for Python
   * using providers_count and providers_get
   */
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
   * Return number of Solvables in pool
   *
   * call-seq:
   *  pool.size -> int
   *
   */
  int size()
  { /* skip Ids 0(reserved) and 1(system) */
    return $self->nsolvables - 1 - 1;
  }

#if defined(SWIGRUBY)
  /*
   * Find out if a solvable is installable (all its dependencies can
   * be satisfied)
   *
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
   * Find solvable by name.
   *
   * Optionally restrict search to a Repository.
   *
   * This function is useful to detect if a Solvable exists at all. If
   * multiple Solvables would match, this call returns any one of them. Use
   * Pool.each_provider to interate over all matches.
   *
   * call-seq:
   *  pool.find("kernel") -> Solvable
   *  pool.find("kernel", this_repo) -> Solvable
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
#else

  /*
   * Search for Solvable attributes
   *
   * See Dataiterator for example code
   *
   * call-seq:
   *  pool.search("match", flags) { |dataiterator| ... }
   *  pool.search("match", flags, solvable) { |dataiterator| ... }
   *  pool.search("match", flags, solvable, key) { |dataiterator| ... }
   *
   */
#if defined(SWIGRUBY)
  void 
#endif
#if defined(SWIGPERL)
  Dataiterator **
#endif
  search(const char *match, int flags, XSolvable *xs = NULL, const char *keyname = NULL) 
  {
    Dataiterator *di;
#if defined(SWIGPERL)
    PtrIndex pi;
    NewPtrIndex(pi,Dataiterator **,0);
#endif
    di = swig_dataiterator_new($self, NULL, match, flags, xs, keyname);
    while( dataiterator_step(di) ) {
#if defined(SWIGRUBY)
      rb_yield(SWIG_NewPointerObj((void*) di, SWIGTYPE_p__Dataiterator, 0));
#endif
#if defined(SWIGPERL)
      AddPtrIndex((&pi),Dataiterator **,di);
#endif
    }
    swig_dataiterator_free(di);
#if defined(SWIGPERL)
    ReturnPtrIndex(pi,Dataiterator **);
#endif
  }
#endif /* SWIGPYTHON */

  /**************************
   * Request management
   */

  %newobject create_request;
  /*
   * Create an empty Request
   *
   * Equivalent to: Request.new
   *
   */
  Request *create_request()
  { return request_new( $self ); }

  /**************************
   * Solver management
   */

#if defined(SWIGRUBY)
  /*
   * Set the repository representing the installed solvables
   *
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
   * Return the repository representing the installed solvables.
   * Returns nil if installed= was not called before.
   *
   * call-seq:
   *  pool.installed -> repository
   *
   */
  Repo *installed()
  {
    return $self->installed;
  }

  %newobject create_solver;
  /*
   * Create a solver for this pool
   *
   * Equivalent to: Solver.new
   *
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

