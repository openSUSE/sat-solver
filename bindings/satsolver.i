%{
/* Document-module: Satsolverx
 *
 * SatSolver is the module namespace for sat-solver bindings.
 *
 * sat-solver is a dependency solver for rpm-style dependencies
 * based on a Satisfyability engine.
 *
 *
 * It might make a lot of sense to make Pool* a singular within
 * the module and use this pointer globally instead of carrying
 * it around in every data structure.
 */
%}

%module satsolverx
%feature("autodoc","1");

%{

/*=============================================================*/
/* HELPER CODE                                                 */
/*=============================================================*/


#if defined(SWIGRUBY)
#include <ruby.h>
#include <rubyio.h>
#endif

/* satsolver core includes */
#include "policy.h"
#include "bitmap.h"
#include "evr.h"
#include "hash.h"
#include "poolarch.h"
#include "pool.h"
#include "poolid.h"
#include "poolid_private.h"
#include "pooltypes.h"
#include "queue.h"
#include "solvable.h"
#include "solver.h"
#include "repo.h"
#include "repo_solv.h"
#include "repo_rpmdb.h"

/* satsolver application layer includes */
#include "applayer.h"
#include "xsolvable.h"
#include "xrepokey.h"
#include "relation.h"
#include "dependency.h"
#include "action.h"
#include "transaction.h"
#include "decision.h"
#include "problem.h"
#include "solution.h"
#include "covenant.h"


static FILE *
poolloadcallback( Pool *pool, Repodata *data, void *vdata )
{
  FILE *fp = 0;
  if (data->location) {
    fp = fopen( data->location, "r" );
    fprintf( stderr, "*** reading %s as %p\n", data->location, fp );
  }
  return fp;
}

					
static int
problem_solutions_iterate_callback( const Solution *s )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solution, 0) );
#endif
  return 0;
}

static int
solver_decisions_iterate_callback( const Decision *d )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*) d, SWIGTYPE_p__Decision, 0));
#endif
  return 0;
}

static int
solver_problems_iterate_callback( const Problem *p )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) p, SWIGTYPE_p__Problem, 0) );
#endif
  return 0;
}

static int
generic_xsolvables_iterate_callback( const XSolvable *xs )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*)xs, SWIGTYPE_p__Solvable, 0));
#endif
  return 0;
}

static int
dependency_relations_iterate_callback( const Relation *rel )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) rel, SWIGTYPE_p__Relation, 0) );
#endif
  return 0;
}

static int
transaction_actions_iterate_callback( const Action *a )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*) a, SWIGTYPE_p__Action, 0));
#endif
  return 0;
}


#if defined(SWIGRUBY)
static int
xsolvable_attr_lookup_callback( void *cbdata, Solvable *s, Repodata *data, Repokey *key, KeyValue *kv )
{
  VALUE *result = (VALUE *)cbdata;
  switch( key->type )
    {
      case TYPE_VOID: *result = Qtrue; break;
      case TYPE_ID:
        if (data->localpool)
	  *result = rb_str_new2( stringpool_id2str( &data->spool, kv->id ) );
	else
	  *result = rb_str_new2( id2str( data->repo->pool, kv->id ) );
      break;
      case TYPE_IDARRAY:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_STR:
        *result = rb_str_new2( kv->str );
      break;
      case TYPE_REL_IDARRAY:
        *result = Qnil; /*FIXME*/
      break;

      case TYPE_ATTR_INT:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_ATTR_CHUNK:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_ATTR_STRING:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_ATTR_INTLIST:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_ATTR_LOCALIDS:
        *result = Qnil; /*FIXME*/
      break;

      case TYPE_COUNT_NAMED:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_COUNTED:
        *result = Qnil; /*FIXME*/
      break;

      case TYPE_IDVALUEARRAY:
        *result = Qnil; /*FIXME*/
      break;

      case TYPE_DIR:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_DIRNUMNUMARRAY:
        *result = Qnil; /*FIXME*/
      break;
      case TYPE_DIRSTRARRAY:
        *result = Qnil; /*FIXME*/
      break;

      case TYPE_U32:
      /*FALLTHRU*/
      case TYPE_CONSTANT:
      /*FALLTHRU*/
      case TYPE_NUM:
        *result = INT2FIX( kv->num );
      break;
    }
  return 1;
}
#endif

%}

/*=============================================================*/
/* BINDING CODE                                                */
/*=============================================================*/

%include exception.i

/*-------------------------------------------------------------*/
/* types and typemaps */

#if defined(SWIGRUBY)
/* copied from /usr/share/swig/ruby/file.i */
%typemap(in) FILE *READ_NOCHECK {
  OpenFile *fptr;

  Check_Type($input, T_FILE);
  GetOpenFile($input, fptr);
  /*rb_io_check_writable(fptr);*/
  $1 = GetReadFile(fptr);
  rb_read_check($1)
}

/* boolean input argument */
%typemap(in) (int bflag) {
   $1 = RTEST( $input );
}
#endif

//==================================
// Typemap: Allow FILE* as PerlIO
//----------------------------------
#if defined(SWIGPERL)
%typemap(in) FILE* {
    $1 = PerlIO_findFILE(IoIFP(sv_2io($input)));
}
#endif

typedef int Id;
typedef unsigned int Offset;

/*
 * just define empty structs to expose the type to SWIG
 */

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

%nodefault _Repodata;
%rename(Repodata) _Repodata;
typedef struct _Repodata {} Repodata;

%nodefault _Repokey;
%rename(Repokey) _Repokey;
typedef struct _Repokey {} XRepokey; /* expose XRepokey as 'Repokey' */

%nodefault _Solvable;
%rename(Solvable) _Solvable;
typedef struct _Solvable {} XSolvable; /* expose XSolvable as 'Solvable' */

%nodefault _Relation;
%rename(Relation) _Relation;
typedef struct _Relation {} Relation;

%nodefault _Dependency;
%rename(Dependency) _Dependency;
typedef struct _Dependency {} Dependency;

%nodefault _Action;
%rename(Action) _Action;
typedef struct _Action {} Action;

%nodefault _Transaction;
%rename(Transaction) _Transaction;
typedef struct _Transaction {} Transaction;

%nodefault solver;
%rename(Solver) solver;
typedef struct solver {} Solver;

%nodefault _Decision;
%rename(Decision) _Decision;
typedef struct _Decision {} Decision;

%nodefault _Problem;
%rename(Problem) _Problem;
typedef struct _Problem {} Problem;

%nodefault _Solution;
%rename(Solution) _Solution;
typedef struct _Solution {} Solution;

%nodefault _Covenant;
%rename(Covenant) _Covenant;
typedef struct _Covenant {} Covenant;

%nodefault _Pool;
typedef struct _Pool {} Pool;
%rename(Pool) _Pool;

/*-------------------------------------------------------------*/
/* Pool */

%{
/*
 * Document-class: Satsolverx::Pool
 *
 * The <code>Pool</code> is main data structure. Everything is reachable via the pool.
 * To solve dependencies of <code>Solvable</code>s, you organize them in <code>Repo</code>s
 * (repositories). The pool knows about all repositories and can
 * create a <code>Solver</code> for solving <code>Transaction</code>s
 */
%}
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

  void prepare()
  { pool_createwhatprovides( $self ); }

  /**************************
   * Repo management
   */

  Repo *add_solv( FILE *fp )
  {
    Repo *repo = repo_create( $self, NULL );
    repo_add_solv( repo, fp );
    return repo;
  }

  Repo *add_solv( const char *fname )
  {
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
    repo_add_rpmdb( repo, NULL, rootdir );
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

  void each()
  { pool_xsolvables_iterate( $self, generic_xsolvables_iterate_callback ); }

  XSolvable *
  find( char *name, Repo *repo = NULL )
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

/*-------------------------------------------------------------*/
/* Repo */

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

  void add_solv( FILE *fp )
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

/*-------------------------------------------------------------*/
/* Repodata */

%extend Repodata {
  /* no constructor, Repodata is embedded in Repo */
  
  /* number of keys in this Repodata */
  int keysize()
  { return $self->nkeys-1; } /* key 0 is reserved */

  /* (File) location of this Repodata, nil if embedded */
  const char *location()
  { return $self->location; }

  /* access Repokey by index */
  XRepokey *key( int i )
  {
    if (i >= 0 && i < $self->nkeys-1)
      return xrepokey_new( $self, i+1 ); /* key 0 is reserved */
    return NULL;
  }
  
#if defined(SWIGRUBY)
  /*
   * Iterate over each key
   */
  void each_key()
  {
    int i;
    for (i = 1; i < $self->nkeys; ++i ) {
      rb_yield( SWIG_NewPointerObj((void*) xrepokey_new( $self, i ), SWIGTYPE_p__Repokey, 0) );
    }
  }
#endif
}

/*-------------------------------------------------------------*/
/* XRepokey */

%extend XRepokey {
  /* no explicit constructor, Repokey is embedded in Repodata */

  ~XRepokey()
  { xrepokey_free( $self ); }
  
  /* name of key */
  const char *name()
  {
    Repokey *key = xrepokey_repokey( $self );
    return my_id2str( $self->repodata->repo->pool, key->name );
  }
  /* type of key */
#if defined(SWIGRUBY)
  VALUE type()
  {
    Repokey *key = xrepokey_repokey( $self );
    VALUE type = Qnil;
    switch( key->type )
    {
      case TYPE_VOID: type = rb_cTrueClass; break;
      case TYPE_ID: type = rb_cString; break;
      case TYPE_IDARRAY: type = rb_cArray; break;
      case TYPE_STR: type = rb_cString; break;
      case TYPE_U32: type = rb_cInteger; break;
      case TYPE_REL_IDARRAY: type = rb_cArray; break;

      case TYPE_ATTR_INT: type = rb_cInteger; break;
      case TYPE_ATTR_CHUNK: type = rb_cString; break;
      case TYPE_ATTR_STRING: type = rb_cString; break;
      case TYPE_ATTR_INTLIST: type = rb_cArray; break;
      case TYPE_ATTR_LOCALIDS: type = rb_cString; break;

      case TYPE_COUNT_NAMED: type = rb_cInteger; break;
      case TYPE_COUNTED: type = rb_cInteger; break;

      case TYPE_IDVALUEARRAY: type = rb_cArray; break;

      case TYPE_DIR: type = rb_cDir; break;
      case TYPE_DIRNUMNUMARRAY: type = rb_cArray; break;
      case TYPE_DIRSTRARRAY: type = rb_cArray; break;

      case TYPE_CONSTANT: type = rb_cInteger; break;
      case TYPE_NUM: type = rb_cNumeric; break;
    }
    return type;
  }
#else
  int type()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->type;
  }
#endif
  /* size of key */
  int size()
  {
    Repokey *key = xrepokey_repokey( $self );
    return key->size;
  }
}

/*-------------------------------------------------------------*/
/* Relation */

%extend Relation {
/* operation */
  %constant int REL_NONE = 0;
  %constant int REL_GT = REL_GT;
  %constant int REL_EQ = REL_EQ;
  %constant int REL_GE = (REL_GT|REL_EQ);
  %constant int REL_LT = REL_LT;
  %constant int REL_NE = (REL_LT|REL_GT);
  %constant int REL_LE = (REL_LT|REL_EQ);
  %constant int REL_AND = REL_AND;
  %constant int REL_OR = REL_OR;
  %constant int REL_WITH = REL_WITH;
  %constant int REL_NAMESPACE = REL_NAMESPACE;

  %feature("autodoc", "1");
  Relation( Pool *pool, const char *name, int op = 0, const char *evr = NULL )
  { return relation_create( pool, name, op, evr ); }
  ~Relation()
  { relation_free( $self ); }

  %rename("to_s") asString();
  const char *asString()
  { return dep2str( $self->pool, $self->id ); }

  Pool *pool()
  { return $self->pool; }

  const char *name()
  {
    Id nameid;
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      nameid = rd->name;
    }
    else {
      nameid = $self->id;
    }
    return my_id2str( $self->pool, nameid );
  }

  const char *evr()
  { return my_id2str( $self->pool, relation_evrid( $self ) ); }

  int op()
  {
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      return rd->flags;
    }
    return 0;
  }

#if defined(SWIGRUBY)
  %alias cmp "<=>";
#endif
  int cmp( const Relation *r )
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_COMPARE ); }

#if defined(SWIGRUBY)
  %alias match "=~";
#endif
  int match( const Relation *r )
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_MATCH_RELEASE ) == 0; }
}

/*-------------------------------------------------------------*/
/* Dependency */

%extend Dependency {
  %constant int DEP_PRV = DEP_PRV;
  %constant int DEP_REQ = DEP_REQ;
  %constant int DEP_CON = DEP_CON;
  %constant int DEP_OBS = DEP_OBS;
  %constant int DEP_REC = DEP_REC;
  %constant int DEP_SUG = DEP_SUG;
  %constant int DEP_SUP = DEP_SUP;
  %constant int DEP_ENH = DEP_ENH;
  %constant int DEP_FRE = DEP_FRE;

  Dependency( XSolvable *xsolvable, int dep )
  { return dependency_new( xsolvable, dep ); }
  ~Dependency()
  { dependency_free( $self ); }

  XSolvable *solvable()
  { return $self->xsolvable; }

  int size()
  { return dependency_size( $self ); }
#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int empty()
  { return dependency_size( $self ) == 0; }

#if defined(SWIGRUBY)
  %alias add "<<";
#endif
  Dependency *add( Relation *rel, int pre = 0 )
  {
    dependency_relation_add( $self, rel, pre );
    return $self;
  }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  Relation *get( int i )
  { return dependency_relation_get( $self, i ); }

  void each()
  { dependency_relations_iterate( $self, dependency_relations_iterate_callback ); }

}

/*-------------------------------------------------------------*/
/* Solvable */

%extend XSolvable {
  %constant int KIND_PACKAGE  = KIND_PACKAGE;
  %constant int KIND_PRODUCT  = KIND_PRODUCT;
  %constant int KIND_PATCH    = KIND_PATCH;
  %constant int KIND_SOURCE   = KIND_SOURCE;
  %constant int KIND_PATTERN  = KIND_PATTERN;
  %constant int KIND_NOSOURCE = KIND_PATTERN;
	    
  XSolvable( Repo *repo, const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( repo, name, evr, arch ); }
  ~XSolvable()
  { return xsolvable_free( $self ); }
  
  Repo *repo()
  { return xsolvable_solvable($self)->repo; }

  const char *name()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->name ); }
  const char *arch()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->arch ); }
  const char *evr()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->evr ); }

  const char *vendor()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->vendor ); }
#if defined(SWIGRUBY)
  %rename( "vendor=" ) set_vendor( const char *vendor );
#endif
  void set_vendor(const char *vendor)
  { xsolvable_solvable($self)->vendor = str2id( $self->pool, vendor, 1 ); }

  %rename("to_s") asString();
  const char *asString()
  {
    if ( $self->id == ID_NULL ) return "";
    return solvable2str( $self->pool, xsolvable_solvable( $self ) );
  }

  /*
   * Dependencies
   */
  Dependency *provides()
  { return dependency_new( $self, DEP_PRV ); }
  Dependency *requires()
  { return dependency_new( $self, DEP_REQ ); }
  Dependency *conflicts()
  { return dependency_new( $self, DEP_CON ); }
  Dependency *obsoletes()
  { return dependency_new( $self, DEP_OBS ); }
  Dependency *recommends()
  { return dependency_new( $self, DEP_REC ); }
  Dependency *suggests()
  { return dependency_new( $self, DEP_SUG ); }
  Dependency *supplements()
  { return dependency_new( $self, DEP_SUP ); }
  Dependency *enhances()
  { return dependency_new( $self, DEP_ENH ); }
  Dependency *freshens()
  { return dependency_new( $self, DEP_FRE ); }
  
  /*
   * Attributes (from Repodata / Repokey)
   */
#if defined(SWIGRUBY)
  VALUE attr( const char *keyname )
  { 
    Id key = str2id( $self->pool, keyname, 0);
    Solvable *s = xsolvable_solvable($self);
    VALUE result;
    if (repo_lookup( s, key, xsolvable_attr_lookup_callback, &result ))
      return result;
    return Qnil;
  }
#endif
}

/*-------------------------------------------------------------*/
/* Action */

%extend Action {
  %constant int INSTALL_SOLVABLE = SOLVER_INSTALL_SOLVABLE;
  %constant int REMOVE_SOLVABLE = SOLVER_ERASE_SOLVABLE;
  %constant int INSTALL_SOLVABLE_NAME = SOLVER_INSTALL_SOLVABLE_NAME;
  %constant int REMOVE_SOLVABLE_NAME = SOLVER_ERASE_SOLVABLE_NAME;
  %constant int INSTALL_SOLVABLE_PROVIDES = SOLVER_INSTALL_SOLVABLE_PROVIDES;
  %constant int REMOVE_SOLVABLE_PROVIDES = SOLVER_ERASE_SOLVABLE_PROVIDES;

  /* no constructor defined, Actions are created by accessing
     a Transaction */
  ~Action()
  { action_free( $self ); }

  int cmd()
  { return $self->cmd; }

  XSolvable *solvable()
  { return action_xsolvable( $self ); }
  const char *name()
  { return action_name( $self ); }

  Relation *relation()
  { return action_relation( $self ); }

}

/*-------------------------------------------------------------*/
/* Transaction */

%extend Transaction {
  Transaction( Pool *pool )
  { return transaction_new( pool ); }

  ~Transaction()
  { transaction_free( $self ); }

  /*
   * Install (specific) solvable
   */
  void install( XSolvable *xs )
  { return transaction_install_xsolvable( $self, xs ); }

  /*
   * Remove (specific) solvable
   */
  void remove( XSolvable *xs )
  { return transaction_remove_xsolvable( $self, xs ); }

  /*
   * Install solvable by name
   * The solver is free to choose any solvable with the given name.
   */
  void install( const char *name )
  { return transaction_install_name( $self, name ); }

  /*
   * Remove solvable by name
   * The solver is free to choose any solvable with the given name.
   */
  void remove( const char *name )
  { return transaction_remove_name( $self, name ); }

  /*
   * Install solvable by relation
   * The solver is free to choose any solvable providing the given
   * relation.
   */
  void install( const Relation *rel )
  { return transaction_install_relation( $self, rel ); }

  /*
   * Remove solvable by relation
   * The solver is free to choose any solvable providing the given
   * relation.
   */
  void remove( const Relation *rel )
  { return transaction_remove_relation( $self, rel ); }

#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Check if the transaction has any actions attached.
   */
  int empty()
  { return ( $self->queue.count == 0 ); }

  /*
   * Return number of actions of this transaction
   */
  int size()
  { return transaction_size( $self ); }

#if defined(SWIGRUBY)
  %rename("clear!") clear();
#endif
  /*
   * Remove all actions of this transaction
   */
  void clear()
  { queue_empty( &($self->queue) ); }

#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  /*
   * Get action by index
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Actions.
   *
   * A Transaction is always considered a set of Actions.
   */
  Action *get( unsigned int i )
  { return transaction_action_get( $self, i ); }

  /*
   * Iterate over each Action of the Transaction.
   */
  void each()
  { transaction_actions_iterate( $self, transaction_actions_iterate_callback ); }
}

/*-------------------------------------------------------------*/
/* Decision */

%extend Decision {
  %constant int DEC_INSTALL = DECISION_INSTALL;
  %constant int DEC_REMOVE = DECISION_REMOVE;
  %constant int DEC_UPDATE = DECISION_UPDATE;
  %constant int DEC_OBSOLETE = DECISION_OBSOLETE;

  /* no constructor defined, Decisions are created by accessing
     the Solver result. See 'Solver.each_decision'. */

  ~Decision()
  { decision_free( $self ); }
  Pool *pool()
  { return $self->pool; }
  int op()
  { return $self->op; }
  XSolvable *solvable()
  { return xsolvable_new( $self->pool, $self->solvable ); }
  XSolvable *reason()
  { return xsolvable_new( $self->pool, $self->reason ); }
}

/*-------------------------------------------------------------*/
/* Problem */

%extend Problem {
  %constant int SOLVER_PROBLEM_UPDATE_RULE = SOLVER_PROBLEM_UPDATE_RULE;
  %constant int SOLVER_PROBLEM_JOB_RULE = SOLVER_PROBLEM_JOB_RULE;
  %constant int SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_PROBLEM_NOT_INSTALLABLE = SOLVER_PROBLEM_NOT_INSTALLABLE;
  %constant int SOLVER_PROBLEM_NOTHING_PROVIDES_DEP = SOLVER_PROBLEM_NOTHING_PROVIDES_DEP;
  %constant int SOLVER_PROBLEM_SAME_NAME = SOLVER_PROBLEM_SAME_NAME;
  %constant int SOLVER_PROBLEM_PACKAGE_CONFLICT = SOLVER_PROBLEM_PACKAGE_CONFLICT;
  %constant int SOLVER_PROBLEM_PACKAGE_OBSOLETES = SOLVER_PROBLEM_PACKAGE_OBSOLETES;
  %constant int SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE = SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE;

  /* no constructor defined, Problems are created by accessing
     the Solver result. See 'Solver.each_problem'. */

  ~Problem()
  { problem_free ($self); }

  Solver *solver()
  { return $self->solver; }

  Transaction *transaction()
  { return $self->transaction; }

  int reason()
  { return $self->reason; }

  XSolvable *source()
  { return xsolvable_new( $self->solver->pool, $self->source ); }

  Relation *relation()
  { return relation_new( $self->solver->pool, $self->relation ); }

  XSolvable *target()
  { return xsolvable_new( $self->solver->pool, $self->target ); }

  void each_solution()
  { problem_solutions_iterate( $self, problem_solutions_iterate_callback );  }

}

/*-------------------------------------------------------------*/
/* Solution */

%extend Solution {
  %constant int SOLUTION_UNKNOWN = SOLUTION_UNKNOWN;
  %constant int SOLUTION_NOKEEP_INSTALLED = SOLUTION_NOKEEP_INSTALLED;
  %constant int SOLUTION_NOINSTALL_SOLV = SOLUTION_NOINSTALL_SOLV;
  %constant int SOLUTION_NOREMOVE_SOLV = SOLUTION_NOREMOVE_SOLV;
  %constant int SOLUTION_NOFORBID_INSTALL = SOLUTION_NOFORBID_INSTALL;
  %constant int SOLUTION_NOINSTALL_NAME = SOLUTION_NOINSTALL_NAME;
  %constant int SOLUTION_NOREMOVE_NAME = SOLUTION_NOREMOVE_NAME;
  %constant int SOLUTION_NOINSTALL_REL = SOLUTION_NOINSTALL_REL;
  %constant int SOLUTION_NOREMOVE_REL = SOLUTION_NOREMOVE_REL;
  %constant int SOLUTION_NOUPDATE = SOLUTION_NOUPDATE;
  %constant int SOLUTION_ALLOW_DOWNGRADE = SOLUTION_ALLOW_DOWNGRADE;
  %constant int SOLUTION_ALLOW_ARCHCHANGE = SOLUTION_ALLOW_ARCHCHANGE;
  %constant int SOLUTION_ALLOW_VENDORCHANGE = SOLUTION_ALLOW_VENDORCHANGE;
  %constant int SOLUTION_ALLOW_REPLACEMENT = SOLUTION_ALLOW_REPLACEMENT;
  %constant int SOLUTION_ALLOW_REMOVE = SOLUTION_ALLOW_REMOVE;
  ~Solution()
  { solution_free ($self); }
  int solution()
  { return $self->solution; }
  /* without the %rename, swig converts it to 's_1'. Ouch! */
  %rename( "s1" ) s1( );
  XSolvable *s1()
  { return xsolvable_new( $self->pool, $self->s1 ); }
  %rename( "n1" ) n1( );
  const char *n1()
  { return id2str( $self->pool, $self->n1 ); }
  %rename( "r1" ) r1( );
  Relation *r1()
  { return relation_new( $self->pool, $self->n1 ); }
  %rename( "s2" ) s2( );
  XSolvable *s2()
  { return xsolvable_new( $self->pool, $self->s2 ); }
  %rename( "n2" ) n2( );
  const char *n2()
  { return id2str( $self->pool, $self->n2 ); }
}


/*-------------------------------------------------------------*/
/* Covenant */

%extend Covenant {
  %constant int INCLUDE_SOLVABLE = SOLVER_INSTALL_SOLVABLE;
  %constant int EXCLUDE_SOLVABLE = SOLVER_ERASE_SOLVABLE;
  %constant int INCLUDE_SOLVABLE_NAME = SOLVER_INSTALL_SOLVABLE_NAME;
  %constant int EXCLUDE_SOLVABLE_NAME = SOLVER_ERASE_SOLVABLE_NAME;
  %constant int INCLUDE_SOLVABLE_PROVIDES = SOLVER_INSTALL_SOLVABLE_PROVIDES;
  %constant int EXCLUDE_SOLVABLE_PROVIDES = SOLVER_ERASE_SOLVABLE_PROVIDES;

  /* no constructor defined, Covenants are created through the Solver,
     see 'Solver.include' and 'Solver.excluding' */
  ~Covenant()
  { covenant_free( $self ); }

  int cmd()
  { return $self->cmd; }

  XSolvable *solvable()
  { return covenant_xsolvable( $self ); }

  const char *name()
  { return covenant_name( $self ); }

  Relation *relation()
  { return covenant_relation( $self ); }
}


/*-------------------------------------------------------------*/
/* Solver */

%extend Solver {

  Solver( Pool *pool, Repo *installed = NULL )
  { return solver_create( pool, installed ); }
  ~Solver()
  { solver_free( $self ); }

  /**************************
   * Solver policies
   */

  /* yeah, thats awkward. But %including solver.h and adding lots
     of %ignores is even worse ... */

  /*
   * Check and fix inconsistencies of the installed system
   *
   * Normally, broken dependencies in the RPM database are silently
   * ignored in order to prevent clutter in the solution.
   * Setting fix_system to 'true' will repair broken system
   * dependencies.
   */
#if defined(SWIGRUBY)
  %typemap(out) int fix_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int fix_system()
  { return $self->fixsystem; }
#if defined(SWIGRUBY)
  %rename( "fix_system=" ) set_fix_system( int bflag );
#endif
  void set_fix_system( int bflag )
  { $self->fixsystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int update_system
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int update_system()
  { return $self->updatesystem; }
#if defined(SWIGRUBY)
  %rename( "update_system=" ) set_update_system( int bflag );
#endif
  void set_update_system( int bflag )
  { $self->updatesystem = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int allow_downgrade
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_downgrade()
  { return $self->allowdowngrade; }
#if defined(SWIGRUBY)
  %rename( "allow_downgrade=" ) set_allow_downgrade( int bflag );
#endif
  void set_allow_downgrade( int bflag )
  { $self->allowdowngrade = bflag; }

  solvable_kind limit_to_kind()
  { return $self->limittokind; }
#if defined(SWIGRUBY)
  %rename( "limit_to_kind=" ) set_limit_to_kind( solvable_kind kind );
#endif
  void set_limit_to_kind( solvable_kind kind )
  { $self->limittokind = kind; }

  /*
   * On package removal, also remove dependant packages.
   *
   * If removal of a package breaks dependencies, the transaction is
   * usually considered not solvable. The dependencies of installed
   * packages take precedence over transaction actions.
   *
   * Setting allow_uninstall to 'true' will revert the precedence
   * and remove all dependant packages.
   */
#if defined(SWIGRUBY)
  %typemap(out) int allow_uninstall
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int allow_uninstall()
  { return $self->allowuninstall; }
#if defined(SWIGRUBY)
  %rename( "allow_uninstall=" ) set_allow_uninstall( int bflag );
#endif
  void set_allow_uninstall( int bflag )
  { $self->allowuninstall = bflag; }

#if defined(SWIGRUBY)
  %typemap(out) int no_update_provide
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int no_update_provide()
  { return $self->noupdateprovide; }
#if defined(SWIGRUBY)
  %rename( "no_update_provide=" ) set_no_update_provide( int bflag );
#endif
  void set_no_update_provide( int bflag )
  { $self->noupdateprovide = bflag; }


  /**************************
   * Covenants
   */

  int covenants_count()
  { return $self->covenantq.count >> 1; }

#if defined(SWIGRUBY)
  %rename("covenants_empty?") covenants_empty();
  %typemap(out) int covenants_empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int covenants_empty()
  { return $self->covenantq.count == 0; }

#if defined(SWIGRUBY)
  %rename("covenants_clear!") covenants_clear();
#endif
  /*
   * Remove all covenants from this solver
   */
  void covenants_clear()
  { queue_empty( &($self->covenantq) ); }

  /*
   * Include (specific) solvable
   * Including a solvable means that it must be installed.
   */
  void include( XSolvable *xs )
  { return covenant_include_xsolvable( $self, xs ); }

  /*
   * Exclude (specific) solvable
   * Excluding a (specific) solvable means that it must not
   * be installed.
   */
  void exclude( XSolvable *xs )
  { return covenant_exclude_xsolvable( $self, xs ); }

  /*
   * Include solvable by name
   * Including a solvable by name means that any solvable
   * with the given name must be installed.
   */
  void include( const char *name )
  { return covenant_include_name( $self, name ); }

  /*
   * Exclude solvable by name
   * Excluding a solvable by name means that any solvable
   * with the given name must not be installed.
   */
  void exclude( const char *name )
  { return covenant_exclude_name( $self, name ); }

  /*
   * Include solvable by relation
   * Including a solvable by relation means that any solvable
   * providing the given relation must be installed.
   */
  void include( const Relation *rel )
  { return covenant_include_relation( $self, rel ); }

  /*
   * Exclude solvable by relation
   * Excluding a solvable by relation means that any solvable
   * providing the given relation must be installed.
   */
  void exclude( const Relation *rel )
  { return covenant_exclude_relation( $self, rel ); }

  /*
   * Get Covenant by index
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Covenants.
   *
   * The solver always considers Covenants as a set.
   */
  Covenant *get_covenant( unsigned int i )
  { return covenant_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Iterate over each Covenant of the Solver.
   */
  void each_covenant()
  {
    int i;
    for (i = 0; i < $self->covenantq.count-1; ) {
      int cmd = $self->covenantq.elements[i++];
      Id id = $self->covenantq.elements[i++];
      rb_yield(SWIG_NewPointerObj((void*) covenant_new( $self->pool, cmd, id ), SWIGTYPE_p__Covenant, 0));
    }
  }
#endif


  /**************************
   * Solve the given Transaction
   * Returns true if a solution was found, else false.
   */
#if defined(SWIGRUBY)
  %typemap(out) int solve
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  int solve( Transaction *t )
  {
    if ($self->covenantq.count) {
      /* FIXME: Honor covenants */
    }
    solver_solve( $self, &(t->queue));
    return $self->problems.count == 0;
  }

  /*
   * Return the number of decisions after solving.
   * If its >0, a solution of the Transaction was found.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns true, the Transaction couldn't be solved.
   * If its ==0, and 'Solver.problems_found' (resp. 'Solver.problems?' for Ruby)
   *   returns false, the Transaction is trivially solved.
   */
  int decision_count()
  { return $self->decisionq.count; }

  void each_decision()
  { return solver_decisions_iterate( $self, solver_decisions_iterate_callback ); }

#if defined(SWIGRUBY)
  %rename("problems?") problems_found();
  %typemap(out) int problems_found
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

  /*
   * Return if problems where found during solving.
   *
   * There is no 'number of problems' available, but it can be computed
   * by iterating over the problems.
   */
  int problems_found()
  { return $self->problems.count != 0; }

  void each_problem( Transaction *t )
  { return solver_problems_iterate( $self, t, solver_problems_iterate_callback ); }

  void each_to_install()
  { return solver_installs_iterate( $self, generic_xsolvables_iterate_callback ); }

  void each_to_remove()
  { return solver_removals_iterate( $self, generic_xsolvables_iterate_callback ); }

  void each_suggested()
  { return solver_suggestions_iterate( $self, generic_xsolvables_iterate_callback); }

#if defined(SWIGPERL)
    SV* getInstallList()
    {
        int b = 0;
        AV *myav = newAV();
        SV *mysv = 0;
        SV *res  = 0;
        int len = self->decisionq.count;
        for (b = 0; b < len; b++) {
	    Solvable *s;
            char *myel;
            Id p = self->decisionq.elements[b];
            if (p < 0) {
                continue; // ignore conflict
            }
            if (p == SYSTEMSOLVABLE) {
                continue; // ignore system solvable
            }
            s = self->pool->solvables + p;
            //printf ("SOLVER NAME: %d %s\n",p,id2str(self->pool, s->name));
            myel = (char*)id2str(self->pool, s->name);
            mysv = sv_newmortal();
            mysv = perl_get_sv (myel,TRUE);
            sv_setpv(mysv, myel);
            av_push (myav,mysv);
        }
        res = newRV((SV*)myav);
        sv_2mortal (res);
        return res;
    }
#endif

};
