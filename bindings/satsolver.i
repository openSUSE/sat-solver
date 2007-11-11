%module satsolverx

%{

extern "C"
{
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
}
#include <sstream>

%}

/*%typemap(ruby, in) FILE* {
  Check_Type($input, T_FILE);
  $1 = RFILE($input)->fptr;

}*/

#ifdef SWIG<Ruby>
FILE * {
    OpenFile *fptr;

    Check_Type($input, T_FILE);    
    GetOpenFile($input, fptr);
    /*rb_io_check_writable(fptr);*/
    $1 = GetReadFile(fptr);
}
#endif

%include "bitmap.h"
%include "evr.h"
%include "hash.h"
%include "poolarch.h"


%alias Pool::nsolvables "size"
%include "pool.h"
%extend _Pool {

  _Pool()
  { return pool_create(); }

  ~_Pool()
  { pool_free($self); }

  void set_arch(const char *arch)
  { pool_setarch($self, arch); }

  int installable(Solvable *s)
  { return pool_installable($self,s); }

  void prepare()
  { pool_prepare($self);}

  void each_repo()
  {
    for (int i = 0; i < $self->nrepos; ++i )
      rb_yield(SWIG_NewPointerObj((void*) $self->repos[i], SWIGTYPE_p__Repo, 0));
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


  Repo* add_empty_repo()
  {
    return pool_addrepo_empty($self);
  }

  Repo * add_repo_solv(FILE *fp, const char *reponame)
  { pool_addrepo_solv($self, fp, reponame); }
};
%newobject pool_create;
%delobject pool_free;


%include "poolid.h"
%include "pooltypes.h"

%include "queue.h"

%extend Queue {

  Queue()
  { Queue *q = new Queue(); queue_init(q); return q; }

  ~Queue()
  { queue_free($self); }

  Queue* clone()
  { Queue *t; queue_clone(t, $self); return t; }

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

%include "solvable.h"

%extend Solvable {

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

  %rename("to_s") asString();
  const char * asString()
  {
    std::stringstream ss;
    if ( $self->repo == NULL )
        return "<UNKNOWN>";
      
    ss << id2str($self->repo->pool, $self->name);
    ss << "-";
    ss << id2str($self->repo->pool, $self->evr);
    ss << "-";
    ss << id2str($self->repo->pool, $self->arch);
    return ss.str().c_str();
  }

}

%include "solver.h"

%extend Solver {
  
  Solver( Pool *pool, Repo *installed ) { return solver_create(pool, installed); }
  ~Solver() { solver_free($self); }

  %rename("fix_system") fixsystem;
  %rename("update_system") updatesystem;
  %rename("allow_downgrade") allowdowngrade;
  %rename("allow_uninstall") allowuninstall;
  %rename("no_update_provide") noupdateprovide;

  void solve(Queue *job) { solve($self, job); }
  void print_decisions() { printdecisions($self); }

  void each_to_install()
  {
    Id p;
    Solvable *s;
    for (int i = 0; i < $self->decisionq.count; i++)
    {
      p = $self->decisionq.elements[i];
      /* conflict */
      if (p < 0)
      continue;
      /* already installed resolvable */
      if (p >= $self->installed->start && p < $self->installed->start + $self->installed->nsolvables)
        continue;
      /** installed resolvable */
      if (p == SYSTEMSOLVABLE)
        continue;

      // getting repo
      s = $self->pool->solvables + p;
      Repo *repo = s->repo;
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

  void each_to_remove()
  {
    Id p;
    Solvable *s;

    /* solvables to be erased */
    for (int i = $self->installed->start;
         i < $self->installed->start + $self->installed->nsolvables;
         i++)
    {
      /* what is this? */
      if ($self->decisionmap[i] > 0)
        continue;

      // getting repo
      s = $self->pool->solvables + i;
      Repo *repo = s->repo;
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }
};

%include "repo.h"

%nodefaultdtor Repo;
%extend Repo {

  const char *name() { return repo_name($self); }

  void each_solvable()
  {
    int i, endof;
    Solvable *s;
    i = $self ? $self->start : 1;
    endof = $self ? $self->start + $self->nsolvables : $self->pool->nsolvables;
    for (; i < endof; i++)
    {
      s = $self->pool->solvables + i;
      //rb_yield(SWIG_NewPointerObj((void*) s, $descriptor(Solvable), 0));
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }
};

%include "repo_solv.h"

%typemap(in) Id {
 $1 = (int) NUM2INT($input);
 printf("Received an integer : %d\n",$1);
}
