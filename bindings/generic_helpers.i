/*-------------------------------------------------------------
 * Generic helpers (SWIG)
 */
 
/* types and typemaps */

%typemap(newfree) char * {
  free($1);
}

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

/*
 * XSolvable array to Perl
 */
%typemap(out) XSolvable ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Solvable, 0);
	/* xsolvable_free((XSolvable *)$1[i]); */
        argvi++;
    }
    free($1);
}

/*
 * Decision* array to Perl
 */
%typemap(out) Decision ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Decision, 0 ); /* SWIG_OWNER | SWIG_SHADOW */
/*	decision_free((Decision *)$1[i]); */
        argvi++;
    }
    free($1);
}
/*
 * Problem* array to Perl
 */
%typemap(out) Problem ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Problem, 0 ); /* SWIG_OWNER | SWIG_SHADOW */
/*	problem_free((Problem *)$1[i]);*/
        argvi++;
    }
    free($1);
}

/*
 * Solution* array to Perl
 */
%typemap(out) Solution ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Solution, 0 ); /* SWIG_OWNER | SWIG_SHADOW */
/*	solution_free((Solution *)$1[i]); */
        argvi++;
    }
    free($1);
}


/*
 * Ruleinfo* array to Perl
 */
%typemap(out) Ruleinfo ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Ruleinfo, 0 ); /* SWIG_OWNER | SWIG_SHADOW */
/*	ruleinfo_free((Ruleinfo *)$1[i]);*/
        argvi++;
    }
    free($1);
}


/*
 * SolutionElement* array to Perl
 */
%typemap(out) SolutionElement ** {
    int n, i;

    for (n = 0; $1[n];)
        n++;

    if (n > items)
        EXTEND(sp, n - items);

    for (i = 0; i < n; i++) {
        ST(argvi) = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__SolutionElement, 0 ); /* SWIG_OWNER | SWIG_SHADOW */
/*	solutionelement_free((SolutionElement  *)$1[i]);*/
        argvi++;
    }
    free($1);
}
#endif

#if defined(SWIGPYTHON)
/*
 * XSolvable array to Python
 */
%typemap(out) XSolvable ** {
    int n, i;
    
    for (n = 0; $1[n];)
        n++;

    $result = PyList_New(n);

    for (i = 0; i < n; i++) {
        PyObject *item = SWIG_NewPointerObj(SWIG_as_voidptr($1[i]), SWIGTYPE_p__Solvable, 0);
        PyList_SetItem($result, i, item);
    }
    free($1);
}
#endif

typedef int Id;
typedef unsigned int Offset;
