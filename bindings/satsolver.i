%module SatSolver

%{

#include "ruby.h"
#include "rubyio.h"
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

/*#include <sstream> */


typedef struct _Relation {
  Offset id;
  Pool *pool;
} Relation;
static Relation *relation_new( Id id, Pool *pool )
{
  if (!id) return NULL;
  Relation *relation = (Relation *)malloc( sizeof( Relation ));
  relation->id = id;
  relation->pool = pool;
  return relation;
}

/* Collection of Relations -> Dependency */
typedef struct _Dependency {
  Offset relation;                 /* offset into repo->idarraydata */
  Solvable *solvable;              /* solvable this dep belongs to */
} Dependency;

static Dependency *dependency_new( Offset relation, Solvable *solvable )
{
  if (!relation) return NULL;
  Dependency *dependency = (Dependency *)malloc( sizeof( Dependency ));
  dependency->relation = relation;
  dependency->solvable = solvable;
  return dependency;
}

%}

/*-------------------------------------------------------------*/
/* types and typemaps */

#if defined(SWIGRUBY)
%typemap(in) FILE* {
  OpenFile *fptr;

  Check_Type($input, T_FILE);
  GetOpenFile($input, fptr);
  /*rb_io_check_writable(fptr);*/
  $1 = GetReadFile(fptr);
}

#endif

typedef int Id;
typedef unsigned int Offset;

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

%nodefault _Solvable;
%rename(Solvable) _Solvable;
typedef struct _Solvable {} Solvable;

%nodefault _Relation;
%rename(Relation) _Relation;
typedef struct _Relation {} Relation;

%nodefault _Dependency;
%rename(Dependency) _Dependency;
typedef struct _Dependency {} Dependency;

/*-------------------------------------------------------------*/
/* Pool */

%newobject pool_create;
%delobject pool_free;

typedef struct _Pool {} Pool;
%rename(Pool) _Pool;

%extend Pool {

  /*
   * Pool management
   */
   
  Pool()
  { return pool_create(); }

  ~Pool()
  { pool_free($self); }

#if defined(SWIGRUBY)
  %rename( "arch=" ) set_arch( const char *arch );
#endif
  void set_arch( const char *arch )
  { pool_setarch( $self, arch ); }

#if defined(SWIGRUBY)
  %rename( "debug=" ) set_debug( int level );
#endif
  void set_debug( int level )
  { pool_setdebuglevel( $self, level ); }

  void prepare()
  { pool_createwhatprovides( $self ); }

  /*
   * Repo management
   */

  int repo_count()
  { return $self->nrepos; }

  void each_repo()
  {
    int i;
    for (i = 0; i < $self->nrepos; ++i )
      rb_yield(SWIG_NewPointerObj((void*) $self->repos[i], SWIGTYPE_p__Repo, 0));
  }

  /*
   * Solvable management
   */

  int size()
  { return $self->nsolvables; }
  
  int installable( Solvable *s )
  { return pool_installable( $self,s ); }

  /* without the %rename, swig converts it to 'id_2solvable'. Ouch! */
  %rename( "id2solvable" ) id2solvable( Id p );
  Solvable *id2solvable(Id p)
  { return pool_id2solvable( $self, p );  }

  void each_solvable()
  {
    Solvable *s;
    Id p;
    for (p = 1, s = $self->solvables + p; p < $self->nsolvables; p++, s++)
    {
      if (!s->name)
        continue;
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

  Solvable *
  select_solvable( char *name, Repo *repo = NULL )
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
    for (; i < end; i++)
    {
      s = pool->solvables + i;
      if (!pool_installable(pool, s))
        continue;
      if (s->name == id)
        queue_push(&plist, i);
    }

    prune_best_version_arch(pool, &plist);

    if (plist.count == 0)
    {
      printf("unknown package '%s'\n", name);
      exit(1);
    }

    id = plist.elements[0];
    queue_free(&plist);

    return pool->solvables + id;
  }

}

/*-------------------------------------------------------------*/
/* Repo */

%extend Repo {
  Repo( Pool *pool, const char *reponame )
  { return repo_create( pool, reponame ); }
  int add_solv( FILE *fp )
  { return repo_add_solv( $self, fp ); }
  int add_solv( const char *fname )
  {
    int result = -1;
    FILE *fp = fopen( fname, "r");
    if (fp) {
      result = repo_add_solv( $self, fp );
      fclose( fp );
    }
    return result;
  }
  int size()
  { return $self->nsolvables; }
  const char *name()
  { return $self->name; }
  int priority()
  { return $self->priority; }
  Pool *pool()
  { return $self->pool; }

  void each_solvable()
  {
    Solvable *s;
    Id p;
    for (p = 0, s = $self->pool->solvables + $self->start; p < $self->nsolvables; p++, s++)
    {
      if (!s)
        continue;
      rb_yield( SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0) );
    }
  }
#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get_solvable "[]";
#endif
  Solvable *get_solvable( int i )
  {
    if (i < 0) return NULL;
    if (i >= $self->nsolvables) return NULL;
    return pool_id2solvable( $self->pool, $self->start + i );
  }
}

/*-------------------------------------------------------------*/
/* Relation */

%extend Relation {
  %constant int REL_GT = 1;
  %constant int REL_EQ = 2;
  %constant int REL_LT = 4;
  %constant int REL_AND = 16;
  %constant int REL_OR = 17;
  %constant int REL_WITH = 18;
  %constant int REL_NAMESPACE = 18;
  Relation( Id id, Pool *pool)
  { return relation_new( id, pool ); }
  Relation( Pool *pool, const char *name, int op = 0, const char *evr = NULL )
  {
    Id name_id = str2id( pool, name, 1 );
    Id evr_id = 0;
    if (evr)
      evr_id = str2id( pool, evr, 1 );
    Id rel = rel2id( pool, name_id, evr_id, op, 1 );
    return relation_new( rel, pool );
  }
  ~Relation()
  { free( $self ); }
  %rename("to_s") asString();
  const char *asString()
  {
    return dep2str( $self->pool, $self->id );
  }
  const char *name()
  {
    Reldep *rd = GETRELDEP( $self->pool, $self->id );
    return id2str( $self->pool, rd->name );
  }
  const char *evr()
  {
    Reldep *rd = GETRELDEP( $self->pool, $self->id );
    return id2str( $self->pool, rd->evr );
  }
  int op()
  {
    Reldep *rd = GETRELDEP( $self->pool, $self->id );
    return rd->flags;
  }
#if defined(SWIGRUBY)
  %alias cmp "<=>";
#endif
  int cmp( const Relation *r )
  { return evrcmp( $self->pool, $self->id, r->id, EVRCMP_COMPARE ); }
#if defined(SWIGRUBY)
  %alias match "=~";
#endif
  int match( const Relation *r )
  { return evrcmp( $self->pool, $self->id, r->id, EVRCMP_MATCH_RELEASE ) == 0; }
}

/*-------------------------------------------------------------*/
/* Dependency */

%extend Dependency {
  Dependency( Offset offset, Solvable *solvable )
  { return dependency_new( offset, solvable ); }
  ~Dependency()
  { free( $self ); }
  int size()
  {
    int i = 0;
    if ($self->relation) {
      Id *ids = $self->solvable->repo->idarraydata + $self->relation;
      while (*ids++)
        ++i;
    }
    return i;
  }
  void each()
  {
    if ($self->relation) {
      Id *ids = $self->solvable->repo->idarraydata + $self->relation;
      while (*ids) {
        rb_yield( SWIG_NewPointerObj((void*) relation_new( *ids, $self->solvable->repo->pool ), SWIGTYPE_p__Relation, 0) );
	++ids;
      }
    }
  }
#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get_relation "[]";
#endif
  Relation *get_relation( unsigned int i )
  {
    if (!$self->relation)
      return NULL;
    /* FIXME: check overflow */
    Id *ids = $self->solvable->repo->idarraydata + $self->relation + i;
    return relation_new( *ids, $self->solvable->repo->pool );
  }
}

/*-------------------------------------------------------------*/
/* Solvable */

%extend Solvable {

  Id id() {
    if (!$self->repo)
      return 0;
    return $self - $self->repo->pool->solvables;
  }

  const char * name()
  { return id2str( $self->repo->pool, $self->name ); }
  Id name_id()
  { return $self->name; }
  const char * arch()
  { return id2str( $self->repo->pool, $self->arch ); }
  Id arch_id()
  { return $self->arch; }
  const char * evr()
  { return id2str( $self->repo->pool, $self->evr ); }
  Id evr_id()
  { return $self->evr; }
  const char * vendor()
  { return id2str( $self->repo->pool, $self->vendor ); }
  Id vendor_id()
  { return $self->vendor; }

  %rename("to_s") asString();
  const char * asString()
  {
    if ( !$self->repo )
        return "<UNKNOWN>";
    return solvable2str( $self->repo->pool, $self );
  }

  /*
   * Dependencies
   */
  Dependency *provides()
  { return dependency_new( $self->provides, $self ); }
  Dependency *requires()
  { return dependency_new( $self->requires, $self ); }
  Dependency *conflicts()
  { return dependency_new( $self->conflicts, $self ); }
  Dependency *obsoletes()
  { return dependency_new( $self->obsoletes, $self ); }
  Dependency *recommends()
  { return dependency_new( $self->recommends, $self ); }
  Dependency *suggests()
  { return dependency_new( $self->suggests, $self ); }
  Dependency *supplements()
  { return dependency_new( $self->supplements, $self ); }
  Dependency *enhances()
  { return dependency_new( $self->enhances, $self ); }
}

/*-------------------------------------------------------------*/

#if 0

%include "poolid.h"
%include "pooltypes.h"

%include "queue.h"

%extend Queue {

  Queue()
  { Queue *q = new Queue(); queue_init(q); return q; }

  ~Queue()
  { queue_free($self); }

  Queue* clone()
  { Queue *t = new Queue(); queue_clone(t, $self); return t; }

  Id shift()
  { return queue_shift($self); }
  
  void push(Id id)
  { /*printf("push id\n");*/ queue_push($self, id); }

  void push( Solvable *s )
  { /*printf("push solvable\n");*/ queue_push($self, (s - s->repo->pool->solvables)); }

  void push_unique(Id id)
  { queue_pushunique($self, id); }

  %rename("empty?") empty();
  bool empty()
  { return ($self->count == 0); }

  void clear()
  { queue_empty($self); }
};
%newobject queue_init;
%delobject queue_free;



%include "solver.h"

%extend Solver {
  
  Solver( Pool *pool, Repo *installed ) { return solver_create(pool, installed); }
  ~Solver() { solver_free($self); }

  %rename("fix_system") fixsystem;
  %rename("update_system") updatesystem;
  %rename("allow_downgrade") allowdowngrade;
  %rename("allow_uninstall") allowuninstall;
  %rename("no_update_provide") noupdateprovide;

  void solve(Queue *job) { solver_solve($self, job); }
  void print_decisions() { printdecisions($self); }

  void each_to_install()
  {
    Id p;
    Solvable *s;
    for (int i = 0; i < $self->decisionq.count; i++)
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
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

  void each_to_remove()
  {
    Id p;
    Solvable *s;

    if (!$self->installed)
      return;
    /* solvables to be erased */
    FOR_REPO_SOLVABLES($self->installed, p, s)
    {
      if ($self->decisionmap[p] >= 0)
        continue;       /* we keep this package */
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }
};

%include "repo.h"
%include "repo_solv.h"

%nodefaultdtor Repo;
%extend Repo {

  /* const char *name() { return repo_name($self); } */

  void each_solvable()
  {
    Id p;
    Solvable *s;
    FOR_REPO_SOLVABLES($self, p, s)
    {
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

  Solvable *add_solvable()
  {
    return pool_id2solvable($self->pool, repo_add_solvable($self));
  }

  void add_solv(FILE *fp)
  {
    repo_add_solv($self, fp);
  }
};

%include "repo_solv.h"

#endif