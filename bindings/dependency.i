/*
 * Document-class: Dependency
 * A dependency is a Set of Relations.
 *
 * There are eight types of dependencies:
 * provides:: These are the relations the Solvable offers.
 *            Implicitly, it always provides its own name and version. This is not listed in provides.
 * requires:: These are the relations required for successful installation of this Solvable.
 * conflicts:: Conflicts are relations only this Solvable might provide on successful installation.
 * obsoletes:: Matching installed Solvables will be removed on installation of this Solvable.
 * recommends:: Weak requires. The solver does a _best_ _effort_ attempt to fulfill recommends.
 * suggests:: Additional relations which are useful to fulfill. The solver ignores those, its at the discretion of the software management application to evaluate suggests.
 * supplements:: Weak inverse requires.
 * enhances:: Inverse suggests.
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
  /* provides Dependency */
  %constant int DEP_PRV = DEP_PRV;
  /* requires Dependency */
  %constant int DEP_REQ = DEP_REQ;
  /* conflicts Dependency */
  %constant int DEP_CON = DEP_CON;
  /* obsoletes Dependency */
  %constant int DEP_OBS = DEP_OBS;
  /* recommends Dependency */
  %constant int DEP_REC = DEP_REC;
  /* suggests Dependency */
  %constant int DEP_SUG = DEP_SUG;
  /* supplements Dependency */
  %constant int DEP_SUP = DEP_SUP;
  /* enhances Dependency */
  %constant int DEP_ENH = DEP_ENH;

  /*
   * Dependency constructor
   * call-seq:
   *  dependency.new(solvable, Satsolver::DEP_REQ) -> Dependency
   *
   */
  Dependency( XSolvable *xsolvable, int dep )
  { return dependency_new( xsolvable, dep ); }
  ~Dependency()
  { dependency_free( $self ); }

  /*
   * The Solvable this Dependency belongs to
   *
   * call-seq:
   *  dependency.solvable -> Solvable
   *
   */
  XSolvable *solvable()
  { return $self->xsolvable; }

  /*
   * Number of relations in this dependency
   * call-seq:
   *  dependency.size -> int
   *
   */
  int size()
  { return dependency_size( $self ); }
#if defined(SWIGRUBY)
  /*
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
  %alias add "<<";
#endif
  /*
   * Add a relation to this Dependency
   *
   * A Dependency is a Set of Relations. There is no ordering implied.
   *
   * call-seq:
   *  dependency << relation -> Dependency
   *  dependency.add(relation,true) -> Dependency
   *
   */
  Dependency *add( Relation *rel, int pre = 0 )
  {
    dependency_relation_add( $self, rel, pre );
    return $self;
  }

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  %alias get "[]";
#endif
  /*
   * Get relation by index
   *
   * This is just a convenience method and does _not_ imply any ordering of Relations.
   *
   * call-seq:
   *  dependency.get(1) -> Relation
   *  dependency[1] -> Relation
   *
   */
  Relation *get( int i )
  { return dependency_relation_get( $self, i ); }

#if defined(SWIGRUBY)
  /*
   * Iterate over all relations in this Dependency
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
