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

    FOR_PROVIDES(p, pp, rel->id) 
      generic_xsolvables_iterate_callback( xsolvable_new( $self, p ) );
  }
#endif

#if defined(SWIGPYTHON)

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
    %pythoncode %{
        def providers(self,what):
          if self.unprepared():
            self.prepare()
          r = range(0,self.providers_count(what))
          while r:
            yield self.providers_get(what, r.pop(0))
    %}
#endif

  void each_provider( const char *name )
  {
#if defined(SWIGRUBY)
    Id p, pp;
    Pool *pool = $self;
    if (!$self->whatprovides)
      pool_createwhatprovides($self);
	  
    FOR_PROVIDES(p, pp, str2id( $self, name, 0) ) 
      generic_xsolvables_iterate_callback( xsolvable_new( $self, p ) );
#endif
  }

  /*
   * Solvable management
   */

  /* number of solvables in pool
   */
  int size()
  { return pool_size( $self ); }

#if defined(SWIGRUBY)
  %rename( "installable?" ) installable( XSolvable *s );
  %typemap(out) int installable
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int installable( XSolvable *s )
  { return pool_installable( $self, pool_id2solvable( s->pool, s->id ) ); }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  /*
   * get solvable by index (0..size-1)
   * index is _not_ the internal id, but used as an array index
   */
  XSolvable *get( int i )
  { return xsolvable_get( $self, i, NULL );  }

#if defined(SWIGRUBY)
  void each()
  { pool_xsolvables_iterate( $self, generic_xsolvables_iterate_callback ); }
#endif

#if defined(SWIGPYTHON)
    %pythoncode %{
        def __iter__(self):
          r = range(0,self.size())
          while r:
            yield self.get(r.pop(0))
    %}
#endif

  XSolvable *find( char *name, Repo *repo = NULL )
  { return xsolvable_find( $self, name, repo ); }

  /**************************
   * Transaction management
   */

  Transaction *create_transaction()
  { return transaction_new( $self ); }

  /**************************
   * Solver management
   */

  Solver* create_solver( Repo *installed = NULL )
  {
    pool_createwhatprovides( $self );
    return solver_create( $self, installed );
  }

}

