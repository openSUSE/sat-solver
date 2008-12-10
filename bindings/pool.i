/*-------------------------------------------------------------*/
/* Pool */

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
 * Document-class: Satsolverx::Pool
 *
 * The <code>Pool</code> is main data structure. Everything is reachable via the pool.
 * To solve dependencies of <code>Solvable</code>s, you organize them in <code>Repo</code>s
 * (repositories). The pool knows about all repositories and can
 * create a <code>Solver</code> for solving <code>Transaction</code>s
 */
%}

%nodefault _Pool;
typedef struct _Pool {} Pool;
%rename(Pool) _Pool;

#if defined(SWIGRUBY)
%mixin Pool "Enumerable";
#endif

%extend Pool {

  /*
   * Pool creation
   */
  Pool( const char *arch = NULL )
  {
    Pool *pool = pool_create();
  
    if (arch) pool_setarch( pool, arch );
    pool_setloadcallback( pool, poolloadcallback, 0 );

    return pool;
  }

  ~Pool()
  { pool_free($self); }

  XSolvable *solvable(int id)
  {
    return xsolvable_new( $self, (Id)id);
  }
  Relation *relation( int rel )
  { return relation_new( $self, (Id)rel ); }

#if defined(SWIGRUBY)
%{
/*
  Document-method: Satsolverx::Pool.set_arch

  Defines the architecture of the pool. Only Solvables with a compatible
  architecture will be considered.
  Setting the architecture to "i686" is a good choice for most 32bit
  systems, 64bit systems most probably need "x86_64"

  call-seq:
    pool.arch = "i686"
*/
%}
  %rename( "arch=" ) set_arch( const char *arch );
#endif
  void set_arch( const char *arch )
  { pool_setarch( $self, arch ); }

#if defined(SWIGRUBY)
  %rename( "debug=" ) set_debug( int level );
#endif
  %feature("autodoc", "Makes the stuff noisy on stderr.") set_debug;
  void set_debug( int level )
  { pool_setdebuglevel( $self, level ); }

  int promoteepoch()
  { return $self->promoteepoch; }
#if defined(SWIGRUBY)
  %rename( "promoteepoch=" ) set_promoteepoch( int level );
#endif
  void set_promoteepoch( int b )
  { $self->promoteepoch = b; }

  int unprepared()
  { return $self->whatprovides == NULL; }

  void prepare()
  { pool_createwhatprovides( $self ); }

  /**************************
   * Repo management
   */

  Repo *add_file( FILE *fp )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_solv( repo, fp );
    return repo;
  }

#if defined(SWIGRUBY)
  Repo *add_solv( VALUE name )
  {
    const char *fname;
    /* try string conversion if not already a string */
    name = rb_check_convert_type( name, T_STRING, "String", "to_s" );
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

  Repo *add_rpmdb( const char *rootdir )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_rpmdb( repo, NULL, rootdir, 0 );
    return repo;
  }

  Repo *create_repo( const char *name )
  { return repo_create( $self, name ); }

  int count_repos()
  { return $self->nrepos; }

  Repo *get_repo( int i )
  {
    if ( i < 0 ) return NULL;
    if ( i >= $self->nrepos ) return NULL;
    return $self->repos[i];
  }

#if defined(SWIGRUBY)
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
   * iterate over providers of relation
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

  int providers_count( const char *name )
  { int i = 0;
    Id v, *vp;
    for (vp = $self->whatprovidesdata + pool_whatprovides($self, str2id( $self, name, 0)) ; (v = *vp++) != 0; )
      ++i;
    return i;
  }

  int providers_count( Relation *rel )
  { int i = 0;
    Id v, *vp;
    for (vp = $self->whatprovidesdata + pool_whatprovides($self, rel->id) ; (v = *vp++) != 0; )
      ++i;
    return i;
  }

  XSolvable *providers_get( const char *name, int i)
  { Id *vp;
    vp = $self->whatprovidesdata + pool_whatprovides($self, str2id( $self, name, 0));
    return xsolvable_new( $self, *(vp + i));
  }
 
  XSolvable *providers_get( Relation *rel, int i)
  { Id *vp;
    vp = $self->whatprovidesdata + pool_whatprovides($self, rel->id);
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

  /* number of solvables in pool
   */
  int size()
  { /* skip Ids 0(reserved) and 1(system) */
    return $self->nsolvables - 1 - 1;
  }

#if defined(SWIGRUBY)
  %rename( "installable?" ) installable( XSolvable *s );
  %typemap(out) int installable
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int installable( XSolvable *s )
  { return pool_installable( $self, pool_id2solvable( s->pool, s->id ) ); }

  /* return number of iterations when iterating over solvables */
  int count()
  { return pool_xsolvables_count( $self ); }

#if defined(SWIGRUBY)
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

  Transaction *create_transaction()
  { return transaction_new( $self ); }

  /**************************
   * Solver management
   */

#if defined(SWIGRUBY)
  %rename( "installed=" ) set_installed( Repo *repo );
#endif
  void set_installed(Repo *installed = NULL)
  {
    pool_set_installed( $self, installed);
  }

  Solver* create_solver()
  {
    pool_createwhatprovides( $self );
    return solver_create( $self );
  }

}

