#ifndef GENERIC_TYPES_H
#define GENERIC_TYPES_H
/*=============================================================*/
/* HELPER CODE                                                 */
/*=============================================================*/

typedef struct {
  void *ptr;
  int size;
  int idx;
} PtrIndex;

#define PtrIndexSize 16
/* alloc PtrIndex with 'init'ial size */
#define NewPtrIndex(pi,type,init) pi.ptr = (type)malloc((((init)==0)?PtrIndexSize:(init) + 1) * sizeof(type)); pi.idx = 0; pi.size = ((init)==0)?PtrIndexSize:(init)
/* add element and realloc eventually */
#define AddPtrIndex(pip,type,element) if (pip->idx == pip->size) { \
	pip->ptr = (type)realloc(pip->ptr, (pip->size + PtrIndexSize) * sizeof(type)); \
	pip->size += PtrIndexSize; \
  } ((type)(pip->ptr))[pip->idx++] = element
/* put final NULL ptr */
#define ReturnPtrIndex(pi,type) ((type)(pi.ptr))[pi.idx] = NULL; return (type)pi.ptr

#if defined(SWIGPYTHON)
#define Swig_Null_p(x) (x == Py_None)
#define Swig_True Py_True
#define Swig_False Py_False
#define Swig_Null Py_None
#define Swig_Type PyObject*
#define Swig_Int(x) PyInt_FromLong(x)
#define Swig_String(x) PyString_FromString(x)
#define Swig_Array() PyList_New(0)
#define Swig_Append(x,y) PyList_Append(x,y)

/* And here goes 'Python is object oriented' down the drain ... */
#define Swig_Type_Type PyTypeObject *
#define Swig_Type_Null &PyBaseObject_Type
#define Swig_Type_Bool &PyBool_Type
#define Swig_Type_Int &PyInt_Type
#define Swig_Type_Long &PyLong_Type
#define Swig_Type_Float &PyFloat_Type
#define Swig_Type_String &PyString_Type
#define Swig_Type_Array &PyList_Type
#define Swig_Type_Number &PyLong_Type
#define Swig_Type_Directory &PyList_Type


#endif

#if defined(SWIGRUBY)
#define Swig_Null_p(x) NIL_P(x)
#define Swig_True Qtrue
#define Swig_False Qfalse
#define Swig_Null Qnil
#define Swig_Type VALUE
#define Swig_Int(x) INT2FIX(x)
#define Swig_String(x) rb_str_new2(x)
#define Swig_Array() rb_ary_new()
#define Swig_Append(x,y) rb_ary_push(x,y)
#define Swig_Type_Type VALUE
#define Swig_Type_Null Qnil
#define Swig_Type_Bool rb_cTrueClass
#define Swig_Type_Int rb_cInteger
#define Swig_Type_Long rb_cInteger
#define Swig_Type_Float rb_cFloat
#define Swig_Type_String rb_cString
#define Swig_Type_Array rb_cArray
#define Swig_Type_Number rb_cNumeric
#define Swig_Type_Directory rb_cDir
#include <ruby.h>
#include <rubyio.h>
#endif

#if defined(SWIGPERL)
SWIGINTERNINLINE SV *SWIG_From_long  SWIG_PERL_DECL_ARGS_1(long value);
SWIGINTERNINLINE SV *SWIG_FromCharPtr(const char *cptr);

#define Swig_Null_p(x) (x == NULL)
#define Swig_True (&PL_sv_yes)
#define Swig_False (&PL_sv_no)
#define Swig_Null NULL
#define Swig_Type SV *
#define Swig_Int(x) SWIG_From_long(x) /* should be SWIG_From_long(x), but Swig declares it too late. FIXME */
#define Swig_String(x) SWIG_FromCharPtr(x) /* SWIG_FromCharPtr(x), also */
#define Swig_Array(x) (SV *)newAV()
#define Swig_Append(x,y) av_push((AV *)x, y)
/* FIXME: perl types */
#define Swig_Type_Type SV *
#define Swig_Type_Null NULL
#define Swig_Type_Bool NULL
#define Swig_Type_Int NULL
#define Swig_Type_Long NULL
#define Swig_Type_Float NULL
#define Swig_Type_String NULL
#define Swig_Type_Array NULL
#define Swig_Type_Number NULL
#define Swig_Type_Directory NULL
#endif

#endif // GENERIC_TYPES_H
