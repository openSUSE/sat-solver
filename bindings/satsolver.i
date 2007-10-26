%module satsolverx

%{

extern "C"
{
#include "ruby.h"
#include "rubyio.h"
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
#include "source.h"
#include "source_solv.h"
}
#include <sstream>

%}

/*%typemap(ruby, in) FILE* {
  Check_Type($input, T_FILE);
  $1 = RFILE($input)->fptr;

}*/

%typemap(ruby,in) FILE * {
    OpenFile *fptr;

    Check_Type($input, T_FILE);    
    GetOpenFile($input, fptr);
    /*rb_io_check_writable(fptr);*/
    $1 = GetReadFile(fptr);
}

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

  void each_source()
  {
    for (int i = 0; i < $self->nsources; ++i )
      rb_yield(SWIG_NewPointerObj((void*) $self->sources[i], SWIGTYPE_p__Source, 0));
  }

  Solvable *
  select_solvable(Source *source, char *name)
  {
    Id id;
    Queue plist;
    int i, end;
    Solvable *s;
    Pool *pool;

    pool = $self;
    id = str2id(pool, name, 1);
    queueinit( &plist);
    i = source ? source->start : 1;
    end = source ? source->start + source->nsolvables : pool->nsolvables;
    for (; i < end; i++)
    {
      s = pool->solvables + i;
      if (!pool_installable(pool, s))
        continue;
      if (s->name == id)
        queuepush(&plist, i);
    }

    prune_best_version_arch(pool, &plist);

    if (plist.count == 0)
    {
      printf("unknown package '%s'\n", name);
      exit(1);
    }

    id = plist.elements[0];
    queuefree(&plist);

    return pool->solvables + id;
  }


  Source* add_empty_source()
  {
    return pool_addsource_empty($self);
  }

  Source * add_source_solv(FILE *fp, const char *sourcename)
  { pool_addsource_solv($self, fp, sourcename); }
};
%newobject pool_create;
%delobject pool_free;


%include "poolid.h"
%include "pooltypes.h"

%include "queue.h"

%extend Queue {

  Queue()
  { Queue *q = new Queue(); queueinit(q); return q; }

  ~Queue()
  { queuefree($self); }

  Queue* clone()
  { Queue *t; clonequeue(t, $self); return t; }

  Id shift()
  { return queueshift($self); }
  
  void push(Id id)
  { /*printf("push id\n");*/ queuepush($self, id); }

  void push( Solvable *s )
  { /*printf("push solvable\n");*/ queuepush($self, (s - s->source->pool->solvables)); }

  void push_unique(Id id)
  { queuepushunique($self, id); }

  %rename("empty?") empty();
  bool empty()
  { return ($self->count == 0); }

  void clear()
  { QUEUEEMPTY($self); }
};
%newobject queueinit;
%delobject queuefree;

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
  { return id2str($self->source->pool, $self->name);}

  %rename("to_s") asString();
  const char * asString()
  {
    std::stringstream ss;
    if ( $self->source == NULL )
        return "<UNKNOWN>";
      
    ss << id2str($self->source->pool, $self->name);
    ss << "-";
    ss << id2str($self->source->pool, $self->evr);
    ss << "-";
    ss << id2str($self->source->pool, $self->arch);
    return ss.str().c_str();
  }

}

%include "solver.h"

%extend Solver {
  
  Solver( Pool *pool, Source *system ) { return solver_create(pool, system); }
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
      if (p >= $self->system->start && p < $self->system->start + $self->system->nsolvables)
        continue;
      /** system resolvable */
      if (p == SYSTEMSOLVABLE)
        continue;

      // getting source
      s = $self->pool->solvables + p;
      Source *source = s->source;
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }

  void each_to_remove()
  {
    Id p;
    Solvable *s;

    /* solvables to be erased */
    for (int i = $self->system->start;
         i < $self->system->start + $self->system->nsolvables;
         i++)
    {
      /* what is this? */
      if ($self->decisionmap[i] > 0)
        continue;

      // getting source
      s = $self->pool->solvables + i;
      Source *source = s->source;
      rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Solvable, 0));
    }
  }
};

%include "source.h"

%nodefaultdtor Source;
%extend Source {

  const char *name() { return source_name($self); }

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

%include "source_solv.h"

%typemap(in) Id {
 $1 = (int) NUM2INT($input);
 printf("Received an integer : %d\n",$1);
}
