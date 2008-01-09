%{
/* Document-module: Satsolverx
 *
 * SatSolver is the module namespace for sat-solver bindings.
 *
 * sat-solver is a dependency solver for rpm-style dependencies
 * based on a Satifyability engine.
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

extern void SWIG_exception( int code, const char *msg );

#if defined(SWIGRUBY)
#include <ruby.h>
#include <rubyio.h>
#endif
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

/************************************************
 * XSolvable
 *
 * we cannot use a Solvable pointer since the Pool might realloc them
 * so we use a combination of Solvable Id and Pool the Solvable belongs
 * to. pool_id2solvable() gives us the pointer.
 *
 * And we cannot use Solvable because its already defined in solvable.h
 * Later, when defining the bindings, a %rename is used to make
 * 'Solvable' available in the target language. Swig tightrope walk.
 */

typedef struct _xsolvable {
  Pool *pool;
  Id id;
} XSolvable;

XSolvable *xsolvable_new( Pool *pool, Id id )
{
  XSolvable *xsolvable = (XSolvable *)malloc( sizeof( XSolvable ));
  xsolvable->pool = pool;
  xsolvable->id = id;
  
  return xsolvable;
}

XSolvable *xsolvable_create( Repo *repo, const char *name, const char *evr, const char *arch )
{
  Id sid = repo_add_solvable( repo );
  Pool *pool = repo->pool;
  XSolvable *xsolvable = xsolvable_new( pool, sid );
  Solvable *s = pool_id2solvable( pool, sid );
  Id nameid = str2id( pool, name, 1 );
  Id evrid = str2id( pool, evr, 1 );
  Id archid, rel;
  if (arch == NULL) arch = "noarch";
  archid = str2id( pool, arch, 1 );
  s->name = nameid;
  s->evr = evrid;
  s->arch = archid;

  /* add self-provides */
  rel = rel2id( pool, nameid, evrid, REL_EQ, 1 );
  s->provides = repo_addid_dep( repo, s->provides, rel, 0 );

  return xsolvable;
}


Solvable *xsolvable_solvable( XSolvable *xs )
{
  return pool_id2solvable( xs->pool, xs->id );
}


/************************************************
 * Id
 *
 */
 
static const char *
my_id2str( Pool *pool, Id id )
{
  if (id == STRID_NULL)
    return NULL;
  if (id == STRID_EMPTY)
    return "";
  return id2str( pool, id );
}


/************************************************
 * Relation
 *
 */

#define REL_NONE 0

typedef struct _Relation {
  Offset id;
  Pool *pool;
} Relation;

static Relation *relation_new( Pool *pool, Id id )
{
  Relation *relation;
  if (!id) return NULL;
  relation = (Relation *)malloc( sizeof( Relation ));
  relation->id = id;
  relation->pool = pool;
  return relation;
}

static Relation *relation_create( Pool *pool, const char *name, int op, const char *evr )
{
  Id name_id = str2id( pool, name, 1 );
  Id evr_id;
  Id rel;
  if (op == REL_NONE)
    return relation_new( pool, name_id );
  if (!evr)
    SWIG_exception( SWIG_NullReferenceError, "REL_NONE operator with NULL evr" );
  evr_id = str2id( pool, evr, 1 );
  rel = rel2id( pool, name_id, evr_id, op, 1 );
  return relation_new( pool, rel );
}

static Id relation_evrid( const Relation *r )
{
  if (ISRELDEP( r->id )) {
    Reldep *rd = GETRELDEP( r->pool, r->id );
    return rd->evr;
  }
  return ID_NULL;
}

/************************************************
 * Dependency
 *
 * Collection of Relations -> Dependency
 */
 
typedef struct _Dependency {
  int dep;                         /* type of dep, any of DEP_xxx */
  XSolvable *xsolvable;            /* xsolvable this dep belongs to */
} Dependency;

#define DEP_PRV 1
#define DEP_REQ 2
#define DEP_CON 3
#define DEP_OBS 4
#define DEP_REC 5
#define DEP_SUG 6
#define DEP_SUP 7
#define DEP_ENH 8
#define DEP_FRE 9

static Dependency *dependency_new( XSolvable *xsolvable, int dep )
{
  Dependency *dependency = (Dependency *)malloc( sizeof( Dependency ));
  dependency->dep = dep;
  dependency->xsolvable = xsolvable;
  return dependency;
}

/* get pointer to offset for dependency */
static Offset *dependency_relations( const Dependency *dep )
{
  Solvable *s;
  if (!dep) return NULL;

  s = xsolvable_solvable( dep->xsolvable );
  switch (dep->dep) {
      case DEP_PRV: return &(s->provides); break;
      case DEP_REQ: return &(s->requires); break;
      case DEP_CON: return &(s->conflicts); break;
      case DEP_OBS: return &(s->obsoletes); break;
      case DEP_REC: return &(s->recommends); break;
      case DEP_SUG: return &(s->suggests); break;
      case DEP_SUP: return &(s->supplements); break;
      case DEP_ENH: return &(s->enhances); break;
      case DEP_FRE: return &(s->freshens); break;
  }
  return NULL;
}


static int dependency_size( const Dependency *dep )
{
  int i = 0;
  Solvable *s;
  Id *ids;
  Offset *relations = dependency_relations( dep );
  if (relations) {
    s = xsolvable_solvable( dep->xsolvable );
    ids = s->repo->idarraydata + *relations;
    while (*ids++)
      ++i;
  }
  return i;
}


/************************************************
 * Action
 *
 * A single 'job' item of a Transaction
 *
 */
 
typedef struct _Action {
  Pool *pool;
  SolverCmd cmd;
  Id id;
} Action;

static Action *action_new( Pool *pool, SolverCmd cmd, Id id )
{
  Action *action = (Action *)malloc( sizeof( Action ));
  action->pool = pool;
  action->cmd = cmd;
  action->id = id;
  return action;
}


/************************************************
 * Transaction
 *
 * A set of Actions to be solved by the Solver
 *
 */
 
typedef struct _Transaction {
  Pool *pool;
  Queue queue;
} Transaction;

static Transaction *transaction_new( Pool *pool )
{
  Transaction *t = (Transaction *)malloc( sizeof( Transaction ));
  t->pool = pool;
  queue_init( &(t->queue) );
  return t;
}

static void transaction_free( Transaction *t )
{
  queue_free( &(t->queue) );
  free( t );
}


/************************************************
 * Decision
 *
 * A successful solver result.
 *
 * Set of 'job items' needed to solve the Transaction.
 *
 */
 
#define DEC_INSTALL 1
#define DEC_REMOVE 2
#define DEC_UPDATE 3
#define DEC_OBSOLETE 4

typedef struct _Decision {
  int op;               /* DEC_{INSTALL,UPDATE,OBSOLETE,REMOVE} */
  Pool *pool;
  Id solvable;
  Id reason;
} Decision;

static Decision *decision_new( Pool *pool, int op, Id solvable, Id reason )
{
  Decision *d = (Decision *)malloc( sizeof( Decision ));
  d->pool = pool;
  d->op = op;
  d->solvable = solvable;
  d->reason = reason;
  return d;
}


/************************************************
 * Problem
 *
 * An unsuccessful solver result
 *
 * If a transaction is not solvable, one or more
 * Problems will be reported by the Solver.
 *
 */

typedef struct _Problem {
  Solver *solver;
  Transaction *transaction;
  Id id;                    /* [PRIVATE] problem id */
  int reason;
  Id source;                /* solvable id */
  Id relation;              /* relation id */
  Id target;                /* solvable id */
} Problem;

#if defined(SWIGRUBY)
static Problem *problem_new( Solver *s, Transaction *t, Id id )
{
  Id prule;

  Problem *p = (Problem *)malloc( sizeof( Problem ));
  p->solver = s;
  p->transaction = t;
  p->id = id;
  prule = solver_findproblemrule( s, id );
  p->reason = solver_problemruleinfo( s, &(t->queue), prule, &(p->relation), &(p->source), &(p->target) ); 
  return p;
}
#endif


/************************************************
 * Solution
 *
 * A possible solution to a Problem.
 *
 * For each reported Problem, the Solver might generate
 * one or more Solutions to make the Transaction solvable.
 *
 */
 
#define SOLUTION_UNKNOWN 0
#define SOLUTION_NOKEEP_INSTALLED 1
#define SOLUTION_NOINSTALL_SOLV 2
#define SOLUTION_NOREMOVE_SOLV 3
#define SOLUTION_NOFORBID_INSTALL 4
#define SOLUTION_NOINSTALL_NAME 5
#define SOLUTION_NOREMOVE_NAME 6
#define SOLUTION_NOINSTALL_REL 7
#define SOLUTION_NOREMOVE_REL 8
#define SOLUTION_NOUPDATE 9
#define SOLUTION_ALLOW_DOWNGRADE 10
#define SOLUTION_ALLOW_ARCHCHANGE 11
#define SOLUTION_ALLOW_VENDORCHANGE 12
#define SOLUTION_ALLOW_REPLACEMENT 13
#define SOLUTION_ALLOW_REMOVE 14

typedef struct _Solution {
  Pool *pool;
  int solution;
  Id s1;
  Id n1;
  Id s2;
  Id n2;
} Solution;

#if defined(SWIGRUBY)
static Solution *solution_new( Pool *pool, int solution, Id s1, Id n1, Id s2, Id n2 )
{
  Solution *s = (Solution *)malloc( sizeof( Solution ));
  s->pool = pool;
  s->solution = solution;
  s->s1 = s1;
  s->n1 = n1;
  s->s2 = s2;
  s->n2 = n2;
  return s;
}
#endif

%}

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

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

%nodefault _Solvable;
%rename(Solvable) _Solvable;
typedef struct _Solvable {} XSolvable;

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

/*-------------------------------------------------------------*/
/* Pool */

%newobject pool_create;
%delobject pool_free;

typedef struct _Pool {} Pool;
%rename(Pool) _Pool;

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
   * Pool management
   */
  Pool( const char *arch = NULL )
  {
    Pool *pool = pool_create();
    if (arch) pool_setarch( pool, arch );
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

  /*
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

  /*
   * Relation management
   */

  Relation *create_relation( const char *name, int op = REL_NONE, const char *evr = NULL )
  { return relation_create( $self, name, op, evr ); }

  /*
   * Solvable management
   */

  int size()
  { return $self->nsolvables; }
  
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
  XSolvable *get( int i )
  {
    if (i < 0) return NULL;
    if (i >= $self->nsolvables) return NULL;
    return xsolvable_new( $self, i );
  }
#if defined(SWIGRUBY)
  void each()
  {
    Solvable *s;
    Id p;
    for (p = 1, s = $self->solvables + p; p < $self->nsolvables; p++, s++)
    {
      if (!s->name)
        continue;
      rb_yield(SWIG_NewPointerObj((void*) xsolvable_new( $self, p ), SWIGTYPE_p__Solvable, 0));
    }
  }
#endif

  XSolvable *
  find( char *name, Repo *repo = NULL )
  {
    Id id;
    Queue plist;
    int i, end;
    Solvable *s;
    Pool *pool;

    pool = $self;
    id = str2id(pool, name, 1);
    queue_init( &plist);
    i = repo ? repo->start : 1;
    end = repo ? repo->start + repo->nsolvables : pool->nsolvables;
    for (; i < end; i++) {
      s = pool->solvables + i;
      if (!pool_installable(pool, s))
        continue;
      if (s->name == id)
        queue_push(&plist, i);
    }

    prune_best_version_arch(pool, &plist);

    if (plist.count == 0) {
      return NULL;
    }

    id = plist.elements[0];
    queue_free(&plist);

    return xsolvable_new( pool, id );
  }

  /*
   * Transaction management
   */
   
  Transaction *create_transaction()
  { return transaction_new( $self ); }

  /*
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

#if defined(SWIGRUBY)
  void each()
  {
    Solvable *s;
    Id p;
    for (p = 0, s = $self->pool->solvables + $self->start; p < $self->nsolvables; p++, s++)
    {
      if (!s)
        continue;
      rb_yield( SWIG_NewPointerObj((void*) xsolvable_new( $self->pool, $self->start + p ), SWIGTYPE_p__Solvable, 0) );
    }
  }
#endif

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  XSolvable *get( int i )
  {
    if (i < 0) return NULL;
    if (i >= $self->nsolvables) return NULL;
    return xsolvable_new( $self->pool, $self->start + i );
  }

  XSolvable *
  find( char *name )
  {
    Id id;
    Queue plist;
    int i, end;
    Solvable *s;
    Pool *pool;

    pool = $self->pool;
    id = str2id( pool, name, 1 );
    queue_init( &plist );
    i = $self->start;
    end = $self->start + $self->nsolvables;
    for (; i < end; i++) {
      s = pool->solvables + i;
      if (!pool_installable( pool, s ))
        continue;
      if (s->name == id)
        queue_push( &plist, i );
    }

    prune_best_version_arch( pool, &plist );

    if (plist.count == 0) {
      return NULL;
    }

    id = plist.elements[0];
    queue_free( &plist );

    return xsolvable_new( pool, id );
  }

}

/*-------------------------------------------------------------*/
/* Relation */

%extend Relation {
/* operation */
#define REL_NONE 0
#define REL_GT 1
#define REL_EQ 2
#define REL_GE 3
#define REL_LT 4
#define REL_NE 5
#define REL_LE 6
#define REL_AND 16
#define REL_OR 17
#define REL_WITH 18
#define REL_NAMESPACE 18

  %feature("autodoc", "1");
  Relation( Pool *pool, const char *name, int op = REL_NONE, const char *evr = NULL )
  { return relation_create( pool, name, op, evr ); }
  ~Relation()
  { free( $self ); }

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
#define DEP_PRV 1
#define DEP_REQ 2
#define DEP_CON 3
#define DEP_OBS 4
#define DEP_REC 5
#define DEP_SUG 6
#define DEP_SUP 7
#define DEP_ENH 8
#define DEP_FRE 9

  Dependency( XSolvable *xsolvable, int dep )
  { return dependency_new( xsolvable, dep ); }
  ~Dependency()
  { free( $self ); }

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
    Solvable *s = xsolvable_solvable( $self->xsolvable );
    Offset *relations = dependency_relations( $self );
    *relations = repo_addid_dep( s->repo, *relations, rel->id, pre ? SOLVABLE_PREREQMARKER : 0 );
    return $self;
  }
  
#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  Relation *get( int i )
  {
    Solvable *s = xsolvable_solvable( $self->xsolvable );
    Offset *relations = dependency_relations( $self );
    /* loop over it to detect end */
    Id *ids = s->repo->idarraydata + *relations;
    while ( i-- >= 0 ) {
      if ( !*ids )
	 break;
      if ( i == 0 ) {
	return relation_new( s->repo->pool, *ids );
      }
      ++ids;
    }
    return NULL;
  }

#if defined(SWIGRUBY)
  void each()
  {
    Solvable *s = xsolvable_solvable( $self->xsolvable );
    Offset *relations = dependency_relations( $self );
    Id *ids = s->repo->idarraydata + *relations;
    while (*ids) {
      rb_yield( SWIG_NewPointerObj((void*) relation_new( s->repo->pool, *ids ), SWIGTYPE_p__Relation, 0) );
      ++ids;
    }
  }
#endif

}

/*-------------------------------------------------------------*/
/* Solvable */

%extend XSolvable {
  XSolvable( Repo *repo, const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( repo, name, evr, arch ); }

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

  /* no constructor defined, Actions are created by accessing a
     Transaction */
  ~Action()
  { free( $self ); }
  
  int cmd()
  { return $self->cmd; }

  XSolvable *solvable()
  {
    if ($self->cmd == SOLVER_INSTALL_SOLVABLE
        || $self->cmd == SOLVER_ERASE_SOLVABLE) {
      return xsolvable_new( $self->pool, $self->id );
    }
    return NULL;
  }

  const char *name()
  {
    if ($self->cmd == SOLVER_INSTALL_SOLVABLE_NAME
        || $self->cmd == SOLVER_ERASE_SOLVABLE_NAME) {
      return my_id2str( $self->pool, $self->id );
    }
    return NULL;
  }

  Relation *relation()
  {
    if ($self->cmd == SOLVER_INSTALL_SOLVABLE_PROVIDES
        || $self->cmd == SOLVER_ERASE_SOLVABLE_PROVIDES) {
      return relation_new( $self->pool, $self->id );
    }
    return NULL;
  }
}

/*-------------------------------------------------------------*/
/* Transaction */

%extend Transaction {
  Transaction( Pool *pool )
  { return transaction_new( pool ); }

  ~Transaction()
  { transaction_free( $self ); }

  Action *shift()
  {
    int cmd = queue_shift( &($self->queue) );
    Id id = queue_shift( &($self->queue) );
    return action_new( $self->pool, cmd, id );
  }
  
  void push( const Action *action )
  {
    if (action == NULL)
      SWIG_exception( SWIG_NullReferenceError, "bad Action" );
    queue_push( &($self->queue), action->cmd );
    queue_push( &($self->queue), action->id );
  }

  void install( XSolvable *s )
  {
    if (s == NULL)
      SWIG_exception( SWIG_NullReferenceError, "bad Solvable" );
    queue_push( &($self->queue), SOLVER_INSTALL_SOLVABLE );
    /* FIXME: check: s->repo->pool == $self->pool */
    queue_push( &($self->queue), s->id );
  }
  void remove( XSolvable *s )
  {
    if (s == NULL)
      SWIG_exception( SWIG_NullReferenceError, "bad Solvable" );
    queue_push( &($self->queue), SOLVER_ERASE_SOLVABLE );
    /* FIXME: check: s->repo->pool == $self->pool */
    queue_push( &($self->queue), s->id );
  }
  void install( const char *name )
  {
    queue_push( &($self->queue), SOLVER_INSTALL_SOLVABLE_NAME );
    queue_push( &($self->queue), str2id( $self->pool, name, 1 ));
  }
  void remove( const char *name )
  {
    queue_push( &($self->queue), SOLVER_ERASE_SOLVABLE_NAME );
    queue_push( &($self->queue), str2id( $self->pool, name, 1 ));
  }
  void install( const Relation *rel )
  {
    if (rel == NULL)
      SWIG_exception( SWIG_NullReferenceError, "bad Relation" );
    queue_push( &($self->queue), SOLVER_INSTALL_SOLVABLE_PROVIDES );
    /* FIXME: check: rel->pool == $self->pool */
    queue_push( &($self->queue), rel->id );
  }
  void remove( const Relation *rel )
  {
    if (rel == NULL)
      SWIG_exception( SWIG_NullReferenceError, "bad Relation" );
    queue_push( &($self->queue), SOLVER_ERASE_SOLVABLE_PROVIDES );
    /* FIXME: check: rel->pool == $self->pool */
    queue_push( &($self->queue), rel->id );
  }

#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int empty()
  { return ( $self->queue.count == 0 ); }

  int size()
  { return $self->queue.count >> 1; }

#if defined(SWIGRUBY)
  %rename("clear!") clear();
#endif
  void clear()
  { queue_empty( &($self->queue) ); }

  Action *get_action( unsigned int i )
  {
    int size, cmd;
    Id id;
    i <<= 1;
    size = $self->queue.count;
    if (i-1 >= size) return NULL;
    cmd = $self->queue.elements[i];
    id = $self->queue.elements[i+1];
    return action_new( $self->pool, cmd, id );
  }

#if defined(SWIGRUBY)
  void each()
  {
    int i;
    for (i = 0; i < $self->queue.count-1; ) {
      int cmd = $self->queue.elements[i++];
      Id id = $self->queue.elements[i++];
      rb_yield(SWIG_NewPointerObj((void*) action_new( $self->pool, cmd, id ), SWIGTYPE_p__Action, 0));
    }
  }
#endif
}

/*-------------------------------------------------------------*/
/* Decision */

%extend Decision {
  %constant int DEC_INSTALL = 1;
  %constant int DEC_REMOVE = 2;
  %constant int DEC_UPDATE = 3;
  %constant int DEC_OBSOLETE = 4;
  
  Decision( Pool *pool, int op, Id solvable, Id reason = 0 )
  { return decision_new( pool, op, solvable, reason ); }
  ~Decision()
  { free( $self ); }
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
  %constant int SOLVER_PROBLEM_UPDATE_RULE = 1;
  %constant int SOLVER_PROBLEM_JOB_RULE = 2;
  %constant int SOLVER_PROBLEM_JOB_NOTHING_PROVIDES_DEP = 3;
  %constant int SOLVER_PROBLEM_NOT_INSTALLABLE = 4;
  %constant int SOLVER_PROBLEM_NOTHING_PROVIDES_DEP = 5;
  %constant int SOLVER_PROBLEM_SAME_NAME = 6;
  %constant int SOLVER_PROBLEM_PACKAGE_CONFLICT = 7;
  %constant int SOLVER_PROBLEM_PACKAGE_OBSOLETES = 8;
  %constant int SOLVER_PROBLEM_DEP_PROVIDERS_NOT_INSTALLABLE = 8;
  ~Problem()
  { free ($self); }

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
  
#if defined(SWIGRUBY)
  void each_solution()
  {
    Id solution = 0;
    while ((solution = solver_next_solution( $self->solver, $self->id, solution )) != 0) {
      Id p, rp, element, what;

      Id s1, s2, n1, n2;
      int code = SOLUTION_UNKNOWN;

      Solver *solver = $self->solver;
      Pool *pool = solver->pool;
      element = 0;
      s1 = s2 = n1 = n2 = 0;
      
      while ((element = solver_next_solutionelement( solver, $self->id, solution, element, &p, &rp)) != 0) {
	if (p == 0) {

          /* job, rp is index into job queue */
          what = $self->transaction->queue.elements[rp];

          switch ($self->transaction->queue.elements[rp - 1]) {
	    case SOLVER_INSTALL_SOLVABLE:
	      s1 = what;
	      if (solver->installed
	          && (pool->solvables + s1)->repo == solver->installed)
		code = SOLUTION_NOKEEP_INSTALLED; /* s1 */
	      else
		code = SOLUTION_NOINSTALL_SOLV; /* s1 */
	    break;
	    case SOLVER_ERASE_SOLVABLE:
	      s1 = what;
	      if (solver->installed
	          && (pool->solvables + s1)->repo == solver->installed)
	        code = SOLUTION_NOREMOVE_SOLV; /* s1 */
	      else
		code = SOLUTION_NOFORBID_INSTALL; /* s1 */
	    break;
	    case SOLVER_INSTALL_SOLVABLE_NAME:
	      n1 = what;
	      code = SOLUTION_NOINSTALL_NAME; /* n1 */
	    break;
	    case SOLVER_ERASE_SOLVABLE_NAME:
	      n1 = what;
	      code = SOLUTION_NOREMOVE_NAME; /* n1 */
	    break;
	    case SOLVER_INSTALL_SOLVABLE_PROVIDES:
	      n1 = what;
	      code = SOLUTION_NOINSTALL_REL; /* r1 */
	      break;
	    case SOLVER_ERASE_SOLVABLE_PROVIDES:
	      n1 = what;
	      code = SOLUTION_NOREMOVE_REL; /* r1 */
	      break;
	    case SOLVER_INSTALL_SOLVABLE_UPDATE:
	      s1 = what;
	      code = SOLUTION_NOUPDATE;
	      break;
	    default:
	      code = SOLUTION_UNKNOWN;
	      break;
	  }
	}
	else {
	  s1 = p;
	  s2 = rp;
	  /* policy, replace p with rp */
	  Solvable *sp = pool->solvables + p;
	  Solvable *sr = rp ? pool->solvables + rp : 0;
	  if (sr) {
	    if (!solver->allowdowngrade
	        && evrcmp( pool, sp->evr, sr->evr, EVRCMP_MATCH_RELEASE ) > 0) {
	      code = SOLUTION_ALLOW_DOWNGRADE;
	    }
	    else if (!solver->allowarchchange
	             && sp->name == sr->name
		     && sp->arch != sr->arch
		     && policy_illegal_archchange( pool, sp, sr ) ) {
	      code = SOLUTION_ALLOW_ARCHCHANGE; /* s1, s2 */
	    }
	    else if (!solver->allowvendorchange
	             && sp->name == sr->name
		     && sp->vendor != sr->vendor
		     && policy_illegal_vendorchange( pool, sp, sr ) ) {
	      n1 = sp->vendor;
	      n2 = sr->vendor;
	      code = SOLUTION_ALLOW_VENDORCHANGE;
	    }
	    else {
	      code = SOLUTION_ALLOW_REPLACEMENT;
	    }
	  }
	  else {
	    code = SOLUTION_ALLOW_REMOVE; /* s1 */
	  }

	}
      }
      Solution *s = solution_new( $self->solver->pool, code, s1, n1, s2, n2 );
      rb_yield( SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solution, 0) );
    }
  }
#endif
}

/*-------------------------------------------------------------*/
/* Solution */

%extend Solution {
  %constant int SOLUTION_UNKNOWN = 0;
  %constant int SOLUTION_NOKEEP_INSTALLED = 1;
  %constant int SOLUTION_NOINSTALL_SOLV = 2;
  %constant int SOLUTION_NOREMOVE_SOLV = 3;
  %constant int SOLUTION_NOFORBID_INSTALL = 4;
  %constant int SOLUTION_NOINSTALL_NAME = 5;
  %constant int SOLUTION_NOREMOVE_NAME = 6;
  %constant int SOLUTION_NOINSTALL_REL = 7;
  %constant int SOLUTION_NOREMOVE_REL = 8;
  %constant int SOLUTION_NOUPDATE = 9;
  %constant int SOLUTION_ALLOW_DOWNGRADE = 10;
  %constant int SOLUTION_ALLOW_ARCHCHANGE = 11;
  %constant int SOLUTION_ALLOW_VENDORCHANGE = 12;
  %constant int SOLUTION_ALLOW_REPLACEMENT = 13;
  %constant int SOLUTION_ALLOW_REMOVE = 14;
  ~Solution()
  { free ($self); }
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
/* Solver */

%extend Solver {

  Solver( Pool *pool, Repo *installed = NULL )
  { return solver_create( pool, installed ); }
  ~Solver()
  { solver_free( $self ); }

  /* yeah, thats awkward. But %including solver.h and adding lots
     of %ignores is even worse ... */

  int fix_system()
  { return $self->fixsystem; }
#if defined(SWIGRUBY)
  %rename( "fix_system=" ) set_fix_system( int i );
#endif
  void set_fix_system( int i )
  { $self->fixsystem = i; }

  int update_system()
  { return $self->updatesystem; }
#if defined(SWIGRUBY)
  %rename( "update_system=" ) set_update_system( int i );
#endif
  void set_update_system( int i )
  { $self->updatesystem = i; }

  int allow_downgrade()
  { return $self->allowdowngrade; }
#if defined(SWIGRUBY)
  %rename( "allow_downgrade=" ) set_allow_downgrade( int i );
#endif
  void set_allow_downgrade( int i )
  { $self->allowdowngrade = i; }

  int allow_uninstall()
  { return $self->allowuninstall; }
#if defined(SWIGRUBY)
  %rename( "allow_uninstall=" ) set_allow_uninstall( int i );
#endif
  void set_allow_uninstall( int i )
  { $self->allowuninstall = i; }

  int no_update_provide()
  { return $self->noupdateprovide; }
#if defined(SWIGRUBY)
  %rename( "no_update_provide=" ) set_no_update_provide( int i );
#endif
  void set_no_update_provide( int i )
  { $self->noupdateprovide = i; }

  void solve( Transaction *t )
  { solver_solve( $self, &(t->queue)); }
  int decision_count()
  { return $self->decisionq.count; }
#if defined(SWIGRUBY)
  void each_decision()
  {
    Pool *pool = $self->pool;
    Repo *installed = $self->installed;
    Id p, *obsoletesmap = create_obsoletesmap( $self );
    Id s, r;
    int op;
    Decision *d;
#if 0   
    if (installed) {
      FOR_REPO_SOLVABLES(installed, p, s) {
	if ($self->decisionmap[p] >= 0)
	  continue;
	if (obsoletesmap[p]) {
	  d = decision_new( pool, DEC_OBSOLETE, s, pool_id2solvable( pool, obsoletesmap[p] ) );
        }
	else {
          d = decision_new( pool, DEC_REMOVE, s, NULL );
	}
        rb_yield(SWIG_NewPointerObj((void*) d, SWIGTYPE_p__Decision, 0));
      }
    }
#endif
    int i;
    for ( i = 0; i < $self->decisionq.count; i++)
    {
      p = $self->decisionq.elements[i];
      r = 0;

      if (p < 0) {     /* remove */
        p = -p;
        s = p;
	if (obsoletesmap[p]) {
	  op = DEC_OBSOLETE;
	  r = obsoletesmap[p];
        }
	else {
	  op = DEC_REMOVE;
	}
      }
      else if (p == SYSTEMSOLVABLE) {
        continue;
      }
      else {
        s = p;
        if (installed) {
	  Solvable *solv = pool_id2solvable( pool, p );
	  if (solv->repo == installed)
	    continue;
	}
        if (!obsoletesmap[p]) {
          op = DEC_INSTALL;
        }
        else {
          op = DEC_UPDATE;
	  int j;
	  for (j = installed->start; j < installed->end; j++) {
	    if (obsoletesmap[j] == p) {
	      r = j;
	      break;
	    }
	  }
        }
      }
      d = decision_new( pool, op, s, r );
      rb_yield(SWIG_NewPointerObj((void*) d, SWIGTYPE_p__Decision, 0));
    }
  }
#endif
#if defined(SWIGRUBY)
  %rename("problems?") problems_found();
  %typemap(out) int problems_found
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int problems_found()
  { return $self->problems.count != 0; }
#if defined(SWIGRUBY)
  void each_problem( Transaction *t )
  {
    Id problem = 0;
    while ((problem = solver_next_problem( $self, problem )) != 0) {
      Problem *p;
      p = problem_new( $self, t, problem );
      rb_yield( SWIG_NewPointerObj((void*) p, SWIGTYPE_p__Problem, 0) );
    }
  }
#endif

#if defined(SWIGRUBY)
  void each_to_install()
  {
    Id p;
    Solvable *s;
    int i;
    for ( i = 0; i < $self->decisionq.count; i++)
    {
      p = $self->decisionq.elements[i];
      if (p <= 0)
        continue;       /* conflicting package, ignore */
      if (p == SYSTEMSOLVABLE)
        continue;       /* system resolvable, always installed */

      // getting repo
      s = $self->pool->solvables + p;
      Repo *repo = s->repo;
      if (!repo || repo == $self->installed)
        continue;       /* already installed resolvable */
      rb_yield(SWIG_NewPointerObj((void*) xsolvable_new( $self->pool, p ), SWIGTYPE_p__Solvable, 0));
    }
  }

  void each_to_remove()
  {
    Id p;
    Solvable *s;

    if (!$self->installed)
      return;
    /* solvables to be removed */
    FOR_REPO_SOLVABLES($self->installed, p, s)
    {
      if ($self->decisionmap[p] >= 0)
        continue;       /* we keep this package */
      rb_yield(SWIG_NewPointerObj((void*) xsolvable_new( $self->pool, p ), SWIGTYPE_p__Solvable, 0));
    }
  }

  void each_suggested()
  {
    int i;
    Solvable *s;
    for (i = 0; i < $self->suggestions.count; i++) {
      s = $self->pool->solvables + $self->suggestions.elements[i];
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

#endif


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
