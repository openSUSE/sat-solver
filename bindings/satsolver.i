%{
/* Document-module: SatSolver
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

%module satsolver
%feature("autodoc","1");

%{

/*=============================================================*/
/* HELPER CODE                                                 */
/*=============================================================*/

#if defined(SWIGPYTHON)
#define Swig_Test(x) (x == Py_None)
#define Swig_True Py_True
#define Swig_False Py_False
#define Swig_Null Py_None
#define Swig_Type PyObject*
#define Swig_Int(x) PyInt_FromLong(x)
#define Swig_String(x) PyString_FromString(x)
#define Swig_Array() PyList_New(0)
#define Swig_Append(x,y) PyList_Append(x,y)
#endif

#if defined(SWIGRUBY)
#define Swig_Test(x) NIL_P(x)
#define Swig_True Qtrue
#define Swig_False Qfalse
#define Swig_Null Qnil
#define Swig_Type VALUE
#define Swig_Int(x) INT2FIX(x)
#define Swig_String(x) rb_str_new2(x)
#define Swig_Array() rb_ary_new()
#define Swig_Append(x,y) rb_ary_push(x,y)
#include <ruby.h>
#include <rubyio.h>
#endif

#if defined(SWIGPERL)
#define Swig_Test(x) (x == NULL)
#define Swig_True (&PL_sv_yes)
#define Swig_False (&PL_sv_no)
#define Swig_Null NULL
#define Swig_Type SV *
#define Swig_Int(x) SWIG_From_long(x)
#define Swig_String(x) SWIG_FromCharPtr(x)
#define Swig_Array(x) NULL
#define Swig_Append(x,y) av_create_and_push(&x, y)
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
#include "job.h"
#include "transaction.h"
#include "decision.h"
#include "problem.h"
#include "solution.h"
#include "covenant.h"


#if defined(SWIGRUBY)
/*
 * iterating over (x)solvables ('yield' in Ruby)
 * (used by Pool, Repo and Solver)
 */

static int
generic_xsolvables_iterate_callback( const XSolvable *xs )
{
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*)xs, SWIGTYPE_p__Solvable, 0) );
  return 0;
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
/*
 * FILE * to Ruby
 * (copied from /usr/share/swig/ruby/file.i)
 */
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

/*
 * FILE * to Perl
 */
#if defined(SWIGPERL)
%typemap(in) FILE* {
    $1 = PerlIO_findFILE(IoIFP(sv_2io($input)));
}
#endif

typedef int Id;
typedef unsigned int Offset;

/*
 * just define empty structs to expose the types to SWIG
 */

%include "pool.i"
%include "repo.i"
%include "repodata.i"
%include "repokey.i"
%include "relation.i"
%include "dependency.i"
%include "solvable.i"
%include "job.i"
%include "transaction.i"
%include "decision.i"
%include "problem.i"
%include "solution.i"
%include "covenant.i"
%include "solver.i"
