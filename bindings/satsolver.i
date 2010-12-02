/*
 Document-module: Satsolver
 =About Satsolver

 Satsolver is the module namespace for sat-solver bindings.

 sat-solver provides a repository data cache and a dependency solver
 for rpm-style dependencies based on a Satisfyability engine.

 See http://en.opensuse.org/Package_Management/Sat_Solver for details
 about the internals of sat-solver.

 Solving needs a Request containing a set of Jobs. Jobs install,
 update, remove, or lock Solvables (packages), names (a Solvable
 providing name), or Relations (+name+ +op+ +version.release+).

 Successful solving creates a Transaction, listing the Solvables to
 install, update, or remove in order to fulfill the Request while
 keeping the installed system consistent.

 Solver errors are reported as Problems. Each Problem has a
 description of what went wrong and a set of Solutions how to
 remediate the Problem.

 ==Working with sat-solver bindings
 
 The sat-solver bindings provide two main functionalities
 - An efficient cache of repository data
 - An ultra-fast dependency solver working on the cached data
 
 The core of the repository cache is represented by the _Pool_. It
 represents the context the solver works in. The Pool holds
 _Solvables_, representing (RPM-based) packages.
 
 Solvables have a
 name, a version and an architecture. Solvables usually have
 _Dependencies_, organized as sets of _Relation_s Solvables can also
 hold additional attribute data, typically everything from the RPM
 header, i.e. _vendor_, _download_ _size_, _install_ _size_, etc.

 Solvables within the Pool are grouped in Repositories. Filling the
 Pool by loading a .+solv+ file, representing a _Repository_, is the
 preferred way.
 
 In a nutshell:
 Pool _has_ _lots_ _of_ Repositories _have_ _lots_ _of_ Solvables
 _have_ _lots_ _of_ Attributes.
 
*/


%module satsolver
%feature("autodoc","1");

#if defined(SWIGRUBY)
%include <ruby.swg>
#endif

#define __type

%{

#include "generic_types.h"

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
#include "transaction.h"

/* satsolver application layer includes */
#include "applayer.h"
#include "xsolvable.h"
#include "xrepokey.h"
#include "relation.h"
#include "dependency.h"
#include "job.h"
#include "request.h"
#include "decision.h"
#include "problem.h"
#include "solution.h"
#include "covenant.h"
#include "ruleinfo.h"
#include "step.h"


#include "generic_helpers.h"

%}

/*=============================================================*/
/* BINDING CODE                                                */
/*=============================================================*/

%include exception.i

%include "generic_helpers.i"

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
%include "request.i"
%include "decision.i"
%include "problem.i"
%include "solution.i"
%include "covenant.i"
%include "ruleinfo.i"
%include "solver.i"
%include "dataiterator.i"
%include "step.i"
%include "transaction.i"
