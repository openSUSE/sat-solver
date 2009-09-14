/*
 * Document-class: Solvable
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
   * Document-method: new
   *
   * Create a Solvable in a Repo, give it name, edition-version-release and optionally an architecture.
   *
   * Architecture defaults to _noarch_
   *
   * See also: Repo.create_solvable
   *
   * call-seq:
   *  Solvable.new(repo, "test", "1.42-0") -> Solvable
   *  Solvable.new(repo, "test", "1.42-0", "ppc") -> Solvable
   *
   */
  XSolvable( Repo *repo, const char *name, const char *evr, const char *arch = NULL )
  { return xsolvable_create( repo, name, evr, arch ); }
  ~XSolvable()
  { return xsolvable_free( $self ); }

  /*
   * call-seq:
   *  solvable.repo -> Repo
   *
   */
  Repo *repo()
  { return xsolvable_solvable($self)->repo; }

  /*
   * call-seq:
   *  solvable.id -> id
   *
   */
  int id()
  { return xsolvable_id($self); }

  /*
   * call-seq:
   *  solvable.pool -> Pool
   *
   */
  Pool *pool()
  { return xsolvable_pool($self); }

  /*
   * call-seq:
   *  solvable.name -> String
   *
   */
  const char *name()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->name ); }
  /*
   * call-seq:
   *  solvable.arch -> String
   *
   */
  const char *arch()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->arch ); }
  /*
   * call-seq:
   *  solvable.evr -> String
   *
   */
  const char *evr()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->evr ); }
  /*
   * call-seq:
   *  solvable.vendor -> String
   *
   */
  const char *vendor()
  { return my_id2str( $self->pool, xsolvable_solvable($self)->vendor ); }
#if defined(SWIGRUBY)
  /*
   * call-seq:
   *  solvable.vendor = "Just me and myself"
   *
   */
  %rename( "vendor=" ) set_vendor( const char *vendor );
#endif
  void set_vendor(const char *vendor)
  { xsolvable_solvable($self)->vendor = str2id( $self->pool, vendor, 1 ); }

#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGPERL)
  SV *
#endif
  /*
   * Get location of corresponding package
   *
   * returns a 2-element tuple of [path (string), medianr (int)]
   *
   * +medianr+ is meaningful only for fixed-media repositories spread
   * across multiple CDs or DVDs.
   *
   * +path+ is +nil+ for non-package solvables.
   *
   */
  __type location()
  {
     Swig_Type result = Swig_Array();
     unsigned int media;
     const char *loc = solvable_get_location(xsolvable_solvable($self), &media);
     if (loc == NULL)
       Swig_Append(result, Swig_Null);
     else
       Swig_Append(result, Swig_String(loc));
     Swig_Append(result, Swig_Int(media));
     return result;
  }
  
%newobject XSolvable::string;
#if defined(SWIGRUBY)
  %rename("to_s") string();
#endif
#if defined(SWIGPYTHON)
  %rename("__str__") string();
#endif
  /*
   * String representation of Solvable
   */
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
  %alias equal "==";
  %typemap(out) int equal
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
#if defined(SWIGPERL)
  /*
   * :nodoc:
   */
  int __eq__( XSolvable *xs )
  { return xsolvable_equal( $self, xs); }
#endif
  /*
   * Equality operator
   *
   */
  int equal( XSolvable *xs )
  { return xsolvable_equal( $self, xs); }

#if defined(SWIGRUBY)
  %alias compare "<=>";
#endif
#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   */
  int __cmp__( XSolvable *xs )
#else
  /*
   * Comparison operator
   *
   */
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
  %rename("identical?") identical;
  %typemap(out) int identical
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif
  /*
   * Identity operator
   *
   * +identical+ represents satsolver semantics for _equality_
   *
   * This might be different from your application needs, beware !
   *
   * call-seq:
   *  solvable.identical?(other_solvable) -> bool
   *
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

%newobject provides;
  /*
   * call-seq:
   *  solvable.provides -> Dependency
   *
   */
  Dependency *provides()
  { return dependency_new( $self, DEP_PRV ); }

%newobject requires;
  /*
   * call-seq:
   *  solvable.requires -> Dependency
   *
   */
  Dependency *requires()
  { return dependency_new( $self, DEP_REQ ); }

%newobject conflicts;
  /*
   * call-seq:
   *  solvable.conflicts-> Dependency
   *
   */
  Dependency *conflicts()
  { return dependency_new( $self, DEP_CON ); }

%newobject obsoletes;
  /*
   * call-seq:
   *  solvable.obsoletes-> Dependency
   *
   */
  Dependency *obsoletes()
  { return dependency_new( $self, DEP_OBS ); }

%newobject recommends;
  /*
   * call-seq:
   *  solvable.recommends -> Dependency
   *
   */
  Dependency *recommends()
  { return dependency_new( $self, DEP_REC ); }

%newobject suggests;
  /*
   * call-seq:
   *  solvable.suggests-> Dependency
   *
   */
  Dependency *suggests()
  { return dependency_new( $self, DEP_SUG ); }

%newobject supplements;
  /*
   * call-seq:
   *  solvable.supplements -> Dependency
   *
   */
  Dependency *supplements()
  { return dependency_new( $self, DEP_SUP ); }

%newobject enhances;
  /*
   * call-seq:
   *  solvable.enhances -> Dependency
   *
   */
  Dependency *enhances()
  { return dependency_new( $self, DEP_ENH ); }

#if defined(SWIGRUBY)
  /*
   * call-seq:
   *  solvable.provides?
   *
   */
  %rename( "provides?" ) does_provide( const char *name );

  /*
   * call-seq:
   *  solvable.provides_any?
   *
   */
  %rename( "provides_any?" ) does_provide_any( Array );

  /*
   * call-seq:
   *  solvable.provides_all?
   *
   */
  %rename( "provides_all?" ) does_provide_all( Array );

  %typemap(out) int does_provide
    "$result = ($1 != 0) ? Qtrue : Qfalse;";
#endif

#if 0
  /*
   * :nodoc:
   */
  int does_provide( const char *name )
  { return dep_match_name( $self, DEP_PRV, name ); }
#if defined(SWIGRUBY)
  /*
   * Check if a Solvable provides a string (regexp match) resp. a Relation.
   *
   * call-seq:
   *   solvable.does_provide("ruby*") -> Boolean
   *   solvable.does_provide(relation) -> Boolean
   *
   */
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
  %alias attr "[]";
  /*
   * Attribute accessor.
   *
   * It takes either a string or a symbol and returns
   * the value of the attribute.
   *
   * If its a symbol, all underline characters are converted
   * to colons. E.g. +:solvable_installsize+ -> +"solvable:installsize"+
   *
   * A +ValueError+ exception is raised if the attribute
   * name does not exist.
   *
   * +nil+ is returned if the attribute name exists but is not set for
   * the solvable.
   *
   *
   * call-seq:
   *  solvable["solvable:installsize"] -> VALUE
   *  solvable.attr("solvable:installsize") -> VALUE
   *  solvable.attr(:solvable_installsize) -> VALUE
   *
   */
  VALUE attr( VALUE attrname )
  {
#endif
#if defined(SWIGPYTHON)
  PyObject *attr( const char *name )
  {
#endif
#if defined(SWIGPERL)
  SV *attr( const char *name )
  {
#endif
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
   * Iterate over all attributes
   *
   * call-seq:
   *  solvable.each_attr do { |attribute| ... }
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
   * Iterate over values
   *
   * call-seq:
   *  solvable.attr_values("foo") do { |attribute| ... }
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
  %rename( "attr?" ) attr_exists( VALUE attrname );
  /*
   * call-seq:
   *  solvable.attr?
   *
   */
  VALUE attr_exists( VALUE attrname )
  {
#endif
#if defined(SWIGPYTHON)
  /*
   * :nodoc:
   */
  PyObject *attr_exists( const char *name )
  {
#endif
#if defined(SWIGPERL)
  /*
   * :nodoc:
   */
  SV *attr_exists( const char *name )
  {
#endif
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

