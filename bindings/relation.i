/*
 * Relation
 */

%nodefault _Relation;
%rename(Relation) _Relation;
typedef struct _Relation {} Relation;


%extend Relation {
/* operation */
  %constant int REL_NONE = 0;
  %constant int REL_GT = REL_GT;
  %constant int REL_EQ = REL_EQ;
  %constant int REL_GE = (REL_GT|REL_EQ);
  %constant int REL_LT = REL_LT;
  %constant int REL_NE = (REL_LT|REL_GT);
  %constant int REL_LE = (REL_LT|REL_EQ);
  %constant int REL_AND = REL_AND;
  %constant int REL_OR = REL_OR;
  %constant int REL_WITH = REL_WITH;
  %constant int REL_NAMESPACE = REL_NAMESPACE;

  %feature("autodoc", "1");
  Relation( Pool *pool, const char *name, int op = 0, const char *evr = NULL )
  { return relation_create( pool, name, op, evr ); }
  ~Relation()
  { relation_free( $self ); }

  %rename("to_s") asString();
  const char *asString()
  { return dep2str( $self->pool, $self->id ); }

  Pool *pool()
  { return $self->pool; }

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

  const char *evr()
  { return my_id2str( $self->pool, relation_evrid( $self ) ); }

  int op()
  {
    if (ISRELDEP( $self->id )) {
      Reldep *rd = GETRELDEP( $self->pool, $self->id );
      return rd->flags;
    }
    return 0;
  }

#if defined(SWIGRUBY)
  %alias cmp "<=>";
#endif
  int cmp( const Relation *r )
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_COMPARE ); }

#if defined(SWIGRUBY)
  %alias match "=~";
#endif
  int match( const Relation *r )
  { return evrcmp( $self->pool, relation_evrid( $self ), relation_evrid( r ), EVRCMP_MATCH_RELEASE ) == 0; }
}
