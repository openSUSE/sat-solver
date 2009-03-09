/*
 * A dependency is a set of Relations. There are eight types of dependencies:
 * * provides
 * * requires
 * * conflicts
 * * obsoletes
 * * recommends
 * * suggests
 * * supplements
 * * enhances
 *
 */

%{
/*
 * iterating over dependency relations ('yield' in Ruby)
 */

#if defined(SWIGRUBY)
static int
dependency_relations_iterate_callback( const Relation *rel )
{
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield( SWIG_NewPointerObj((void*) rel, SWIGTYPE_p__Relation, 0) );
  return 0;
}
#endif

%}


%nodefault _Dependency;
%rename(Dependency) _Dependency;
typedef struct _Dependency {} Dependency;


#if defined(SWIGRUBY)
%mixin Dependency "Enumerable";
#endif

%extend Dependency {
  %constant int DEP_PRV = DEP_PRV;
  %constant int DEP_REQ = DEP_REQ;
  %constant int DEP_CON = DEP_CON;
  %constant int DEP_OBS = DEP_OBS;
  %constant int DEP_REC = DEP_REC;
  %constant int DEP_SUG = DEP_SUG;
  %constant int DEP_SUP = DEP_SUP;
  %constant int DEP_ENH = DEP_ENH;

  /*
   * Document-method: new
   * call-seq:
   *  dependency.new(solvable, Satsolver::DEP_REQ) -> Dependency
   *
   */
  Dependency( XSolvable *xsolvable, int dep )
  { return dependency_new( xsolvable, dep ); }
  ~Dependency()
  { dependency_free( $self ); }

  /*
   * Document-method: solvable
   * call-seq:
   *  dependency.solvable -> Solvable
   *
   */
  XSolvable *solvable()
  { return $self->xsolvable; }

  /*
   * Document-method: size
   * Number of relations in this dependency
   * call-seq:
   *  dependency.size -> int
   *
   */
  int size()
  { return dependency_size( $self ); }
#if defined(SWIGRUBY)
  /*
   * Document-method: empty?
   * If the dependency is empty
   * call-seq:
   *  dependency.empty? -> bool
   *
   */
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  int empty()
  { return dependency_size( $self ) == 0; }

#if defined(SWIGRUBY)
  /*
   * Document-method: <<
   * Add a relation to a dependency
   * call-seq:
   *  dependency << relation -> Dependency
   *  dependency.add(relation,true) -> Dependency
   *
   */
  %alias add "<<";
#endif
  Dependency *add( Relation *rel, int pre = 0 )
  {
    dependency_relation_add( $self, rel, pre );
    return $self;
  }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  /*
   * Document-method: []
   * call-seq:
   *  dependency[1] -> Relation
   *
   */
  %alias get "[]";
#endif
  Relation *get( int i )
  { return dependency_relation_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Document-method: each
   * call-seq:
   *  dependency.each { |relation| ... }
   *
   */
  void each()
  { dependency_relations_iterate( $self, dependency_relations_iterate_callback ); }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def __iter__(self):
          r = range(0,self.size())
          while r:
            yield self.get(r.pop(0))
    %}
#endif

}
