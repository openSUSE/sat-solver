/*
 * Document-class: Relation
 * A Relation is a _name_, _operation_, _evr_ triple, representing
 * items of Solvable dependencies.
 *
 */

%nodefault _Relation;
%rename(Relation) _Relation;
typedef struct _Relation {} Relation;


%extend Relation {
  /* operation constants */
  
  /* the no-op relation */
  %constant int REL_NONE = 0;
  /* greater-than */
  %constant int REL_GT = REL_GT;
  /* equality */
  %constant int REL_EQ = REL_EQ;
  /* greater-equal */
  %constant int REL_GE = (REL_GT|REL_EQ);
  /* less-than */
  %constant int REL_LT = REL_LT;
  /* not-equal */
  %constant int REL_NE = (REL_LT|REL_GT);
  /* less-equal */
  %constant int REL_LE = (REL_LT|REL_EQ);
  /* and, relation between relations */
  %constant int REL_AND = REL_AND;
  /* or, relation between relations */
  %constant int REL_OR = REL_OR;
  /* with, relation between relations, affecting the same solvable */
  %constant int REL_WITH = REL_WITH;
  /* namespace */
  %constant int REL_NAMESPACE = REL_NAMESPACE;

  /*
   * Document-method: new
   * Create a new relation inside Pool. Gets a name, plus optionally operand and edition-version-release (evr)
   *
   * see also: Pool.create_relation
   *
   * call-seq:
   *    Relation.new( pool, "kernel" ) -> Relation
   *    Relation.new( pool, "kernel", REL_GT, "2.6.26" ) -> Relation
   *
   */
  Relation( Pool *pool, const char *name, int op = 0, const char *evr = NULL )
  { return relation_create( pool, name, op, evr ); }
  ~Relation()
  { relation_free( $self ); }

#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   */
  %rename("__str__") string();
#endif

%newobject Relation::string;
  /*
   * String representation of this Relation
   */
  const char *string()
  { return relation_string($self); }

  const Pool *pool()
  { return $self->pool; }

  /*
   * The name part of the Relation
   */
  const char *name()
  {
    Id nameid;
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      nameid = rd->name;
    }
    else {
      nameid = $self->id;
    }
    return my_id2str( $self->pool, nameid );
  }

  /*
   * The evr (edition-version.release) part of the Relation
   *
   */
  const char *evr()
  { return my_id2str( $self->pool, relation_evrid( $self ) ); }

  /*
   * The operation of the Relation
   *
   * One of +Satsolver::REL_*+
   *
   */
  int op()
  {
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      return rd->flags;
    }
    return 0;
  }

  /*
   * A string representation of the operation
   *
   * See also: +op+
   *
   */
  const char *op_s()
  {
    static const char *ops[] = {
      "", ">", "=", ">=",
      "<", "<>", "<=", "<=>"
    };
    unsigned int op = 0;
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      op = rd->flags;
    }
    if (op < 8)
      return ops[op];
    switch (op) {
      case REL_AND: return "and";
      case REL_OR: return "or";
      case REL_WITH: return "with";
      case REL_NAMESPACE: return "namespace";
      case REL_ARCH: return "arch";
      default: break;
    }
    return "<op>";
  }

#if defined(SWIGRUBY)
  %alias compare "<=>";
#endif
#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   */
  int __cmp__( const Relation *r )
#else
  /*
   * Comparison operator
   *
   * returning <0 (smaller), 0 (equal) or >0 (greater)
   *
   */
  int compare( const Relation *r )
#endif
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_COMPARE ); }

#if defined(SWIGRUBY)
  %alias match "=~";
#endif
  /*
   * Match operator
   *
   * Returning +true+ or +false+
   *
   */
  int match( const Relation *r )
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_MATCH_RELEASE ) == 0; }

#if defined(SWIGRUBY)
  %alias equal "==";
#endif
  /*
   * Equality operator
   *
   * Returns +true+ if both Relations are equal (equal +name+, +evr+ and +op+)
   *
   */
  int equal( const Relation *r )
  { return relation_evrid( $self ) == relation_evrid( r ); }

}

