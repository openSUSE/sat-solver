/*
 * Dependency
 */

%{
/*
 * iterating over dependency relations ('yield' in Ruby)
 */

static int
dependency_relations_iterate_callback( const Relation *rel )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) rel, SWIGTYPE_p__Relation, 0) );
#endif
  return 0;
}

%}


%nodefault _Dependency;
%rename(Dependency) _Dependency;
typedef struct _Dependency {} Dependency;


%extend Dependency {
  %constant int DEP_PRV = DEP_PRV;
  %constant int DEP_REQ = DEP_REQ;
  %constant int DEP_CON = DEP_CON;
  %constant int DEP_OBS = DEP_OBS;
  %constant int DEP_REC = DEP_REC;
  %constant int DEP_SUG = DEP_SUG;
  %constant int DEP_SUP = DEP_SUP;
  %constant int DEP_ENH = DEP_ENH;

  Dependency( XSolvable *xsolvable, int dep )
  { return dependency_new( xsolvable, dep ); }
  ~Dependency()
  { dependency_free( $self ); }

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
    dependency_relation_add( $self, rel, pre );
    return $self;
  }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  Relation *get( int i )
  { return dependency_relation_get( $self, i ); }

#if defined(SWIGRUBY)
  void each()
  { dependency_relations_iterate( $self, dependency_relations_iterate_callback ); }
#endif

}

