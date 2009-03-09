/*
 * Solvable is the representation of a (RPM) package within Satsolver.
 *
 */

%nodefault _Solvable;
%rename(Solvable) _Solvable;
typedef struct _Solvable {} XSolvable; /* expose XSolvable as 'Solvable' */


%extend XSolvable {

  %constant int KIND_PACKAGE  = KIND_PACKAGE;
  %constant int KIND_PRODUCT  = KIND_PRODUCT;
  %constant int KIND_PATCH    = KIND_PATCH;
  %constant int KIND_SOURCE   = KIND_SOURCE;
  %constant int KIND_PATTERN  = KIND_PATTERN;
  %constant int KIND_NOSOURCE = KIND_PATTERN;

  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  XSolvable( Repo *repo, const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( repo, name, evr, arch ); }
  ~XSolvable()
  { return xsolvable_free( $self ); }

  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Repo *repo()
  { return xsolvable_solvable($self)->repo; }

  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Pool *pool()
  { return xsolvable_solvable($self)->repo->pool; }

  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  const char *name()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->name ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  const char *arch()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->arch ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  const char *evr()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->evr ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  const char *vendor()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->vendor ); }
#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename( "vendor=" ) set_vendor( const char *vendor );
#endif
  void set_vendor(const char *vendor)
  { xsolvable_solvable($self)->vendor = str2id( $self->pool, vendor, 1 ); }

%newobject XSolvable::string;
#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  const char *string()
  {
    const char *s;
    if ( $self->id == ID_NULL )
      s = "";
    else
      s = solvable2str( $self->pool, xsolvable_solvable( $self ) );
    return strdup(s);
  }

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %alias equal "==";
  %typemap(out) int equal
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
#if defined(SWIGPERL)
  int __eq__( XSolvable *xs )
  { return xsolvable_equal( $self, xs); }
#endif
  int equal( XSolvable *xs )
  { return xsolvable_equal( $self, xs); }

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %alias compare "<=>";
#endif
#if defined(SWIGPYTHON)
  int __cmp__( XSolvable *xs )
#else
  int compare( XSolvable *xs )
#endif
  {
    Solvable *s1 = xsolvable_solvable( $self );
    Solvable *s2 = xsolvable_solvable( xs );
    const char *n1 = 0, *n2 = 0;
    int i = 0;

    if (($self->pool != xs->pool)
        || (s1->name != s2->name))
      {
        n1 = id2str( $self->pool, s1->name );
        n2 = id2str( xs->pool, s2->name );
        i = strcmp( n1, n2 );
      }
    if (i == 0) /* names are equal */
      {
        if ($self->pool == xs->pool)
          i = evrcmp( $self->pool, s1->evr, s2->evr, EVRCMP_COMPARE );
        else
        {
          n1 = id2str( $self->pool, s1->evr );
          n2 = id2str( xs->pool, s2->evr );
          i = strcmp( n1, n2 );
        }
      }
    return i;
  }

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.identical?(other_solvable) -> bool
   *
   */
  %rename("identical?") identical;
  %typemap(out) int identical
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  /*
   * solvable_identical represents satsolver semantics for 'equality'
   * This might be different from your application needs, beware !
   */
  int identical( XSolvable *xs )
  {
    Solvable *s1 = xsolvable_solvable( $self );
    Solvable *s2 = xsolvable_solvable( xs );
    if ($self->pool == xs->pool)
      return solvable_identical(s1, s2);
    return 0;
  }

  /*
   * Dependencies
   */
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *provides()
  { return dependency_new( $self, DEP_PRV ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *requires()
  { return dependency_new( $self, DEP_REQ ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *conflicts()
  { return dependency_new( $self, DEP_CON ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *obsoletes()
  { return dependency_new( $self, DEP_OBS ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *recommends()
  { return dependency_new( $self, DEP_REC ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *suggests()
  { return dependency_new( $self, DEP_SUG ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *supplements()
  { return dependency_new( $self, DEP_SUP ); }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  Dependency *enhances()
  { return dependency_new( $self, DEP_ENH ); }

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename( "provides?" ) does_provide( const char *name );
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename( "provides_any?" ) does_provide_any( Array );
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename( "provides_all?" ) does_provide_all( Array );
  %typemap(out) int does_provide
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

#if 0
  int does_provide( const char *name )
  { return dep_match_name( $self, DEP_PRV, name ); }
#if defined(SWIGRUBY)
  int does_provide( const char *regexp )
  { return dep_match_regexp( $self, DEP_PRV, regexp ); }
#endif
  int does_provide( const Relation *rel )
  { return dep_match_relation( $self, DEP_PRV, rel ); }
#endif

  /*
   * Attributes (from Repodata / Repokey)
   */


  /*
   * access attribute via []
   */

#if defined(SWIGRUBY)
  /* %rename is rejected by swig for [] */
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %alias attr "[]";
  VALUE attr( VALUE attrname )
#endif
#if defined(SWIGPYTHON)
  PyObject *attr( const char *name )
#endif
#if defined(SWIGPERL)
  SV *attr( const char *name )
#endif
  {
    Swig_Type result = Swig_Null;
    Id key;
    Solvable *s;
    Dataiterator di;
#if defined(SWIGRUBY)
    char *name;

    if (SYMBOL_P(attrname)) {
      char *colon;
      name = (char *)rb_id2name( SYM2ID( attrname ) );
      colon = name;
      while ((colon = strchr( colon, '_'))) {
        *colon++ = ':';
      }
    }
    else
      name = StringValuePtr( attrname );
#endif
    if (!name)
      SWIG_exception( SWIG_ValueError, "Attribute name missing" );

    /* key existing in pool ? */
    key = str2id( $self->pool, name, 0);
    if (key == ID_NULL)
      SWIG_exception( SWIG_ValueError, "No such attribute name" );

    s = xsolvable_solvable($self);
    dataiterator_init(&di, s->repo->pool, s->repo, $self->id, key, 0, 0);
    if (dataiterator_step(&di))
    {
      result = dataiterator_value( &di );
    }

#if defined(SWIGPYTHON) || defined(SWIGPERL)/* needed for SWIG_Exception */
fail:
#endif
#if defined(SWIGPYTHON)
    Py_INCREF(result);
#endif
    return result;
  }

  /*
   * iterate over all attributes
   */

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  void each_attr()
  {
    Solvable *s = xsolvable_solvable($self);
    Dataiterator di;
    VALUE value;
    dataiterator_init(&di, s->repo->pool, s->repo, $self->id, 0, 0, SEARCH_NO_STORAGE_SOLVABLE);
    while (dataiterator_step(&di))
    {
      value = dataiterator_value ( &di );
      rb_yield( value );
    }
  }
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  void attr_values(const char *name)
  {
    Solvable *s = xsolvable_solvable($self);
    Dataiterator di;
    VALUE value;
    dataiterator_init(&di, s->repo->pool, s->repo, $self->id, str2id(s->repo->pool,name,0), 0, 0);
    while (dataiterator_step(&di))
    {
      value = dataiterator_value ( &di );
      rb_yield( value );
    }
  }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def attrs(self):
          d = Dataiterator(self.repo().pool(),self.repo(),None,SEARCH_NO_STORAGE_SOLVABLE,self)
          while d.step():
            yield d.value()
        def attr_values(self,name):
          d = Dataiterator(self.repo().pool(),self.repo(),None,0,self,name)
          while d.step():
            yield d.value()
    %}
#endif
#if defined(SWIGPERL)
  %perlcode %{
    sub attr_values {
      my ($self, $name) = @_;
      my @values;
      
      my $di = new satsolver::Dataiterator($self->repo()->pool(),$self->repo(),undef,0,$self,$name);
      while ($di->step() != 0) {
        push @values, $di->value();
      }

      return wantarray ? @values : $values[0];
    }
  %}
#endif

  /*
   * check existance of attribute
   */

#if defined(SWIGRUBY)
  /*
   * Document-method: 
   * call-seq:
   *  solvable.
   *
   */
  %rename( "attr?" ) attr_exists( VALUE attrname );
  VALUE attr_exists( VALUE attrname )
#endif
#if defined(SWIGPYTHON)
  PyObject *attr_exists( const char *name )
#endif
#if defined(SWIGPERL)
  SV *attr_exists( const char *name )
#endif
  {
    Swig_Type result = Swig_False;
#if defined(SWIGRUBY)
    char *name;

    if (SYMBOL_P(attrname)) {
      char *colon;
      name = (char *)rb_id2name( SYM2ID( attrname ) );
      colon = name;
      while ((colon = strchr( colon, '_'))) {
        *colon++ = ':';
      }
    }
    else
      name = StringValuePtr( attrname );
#endif

    if (name) {
      /* key existing in pool/repo for this solvable ? */
      Id key;
      key = str2id( $self->pool, name, 0);
      if (key != ID_NULL) {
        Solvable *s = xsolvable_solvable($self);
        Dataiterator di;
        dataiterator_init(&di, s->repo->pool, s->repo, $self->id, key, 0, 0);
        if (dataiterator_step(&di))
          result = Swig_True;
      }
    }
#if defined(SWIGPYTHON)
    Py_INCREF(result);
#endif
    return result;
  }
}

