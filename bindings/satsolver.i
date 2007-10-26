%module satsolver

%{

#include "ruby.h"
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

#define true (1==1)
#define false !true

%}

%include "bitmap.h"
%include "evr.h"
%include "hash.h"
%include "poolarch.h"
%include "pool.h"
%include "poolid.h"
%include "poolid_private.h"
%include "pooltypes.h"
%include "queue.h"
%include "solvable.h"
%include "solver.h"
%include "source.h"
%include "source_solv.h"

