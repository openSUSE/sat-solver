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

%typemap(in) Id {
 $1 = (int) NUM2INT($input);
}

%typemap(in) Offset {
 $1 = (unsigned int) NUM2INT($input);
}
#endif

%nodefault _Repo;
%rename(Repo) _Repo;
typedef struct _Repo {} Repo;

%nodefault _Solvable;
%rename(Solvable) _Solvable;
struct _Solvable {};

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

  Solvable *id2solvable(Id p)
  {
    return pool_id2solvable($self, p);
  }

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
  select_solvable(Repo *repo, char *name)
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
}

#if 0


/*-------------------------------------------------------------*/
/* Solvable */

%include "solvable.h"

%extend Solvable {

  Id id() {
    if (!$self->repo)
      return 0;
    return $self - $self->repo->pool->solvables;
  }

  //%typemap(ruby,in) Id {
  //  $1 = id2str($self->pool, $input);
  //}

  //%typemap(ruby,out) Id {
  //  $result = rb_str_new2(str2id($self->pool,$1));
  //}

  //%rename(name_id) name();
  %ignore name;
  const char * name()
  { return id2str($self->repo->pool, $self->name);}
  %ignore arch;
  const char * arch()
  { return id2str($self->repo->pool, $self->arch);}
  %ignore evr;
  const char * evr()
  { return id2str($self->repo->pool, $self->evr);}
  %ignore vendor;
  const char * vendor()
  { return id2str($self->repo->pool, $self->vendor);}

  %rename("to_s") asString();
  const char * asString()
  {
    if ( !$self->repo )
        return "<UNKNOWN>";
    return solvable2str($self->repo->pool, $self);
  }

}

/*-------------------------------------------------------------*/

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