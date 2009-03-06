/*
 * Repodata
 */

%nodefault _Repodata;
%rename(Repodata) _Repodata;
typedef struct _Repodata {} Repodata;


/* no constructor, Repodata is embedded in Repo */
%extend Repodata {
  
  /*
   * Document-method: size
   * number of keys in this Repodata
   */
  int size()
  { return $self->nkeys-1; } /* key 0 is reserved */

  /*
   * Document-method: key
   * access Repokey by index
   */
#if defined(SWIGRUBY)
  %alias key "[]";
#endif
  XRepokey *key( int i )
  {
    if (i >= 0 && i < $self->nkeys-1)
      return xrepokey_new( $self->keys + i + 1, $self->repo, $self ); /* key 0 is reserved */
    return NULL;
  }
  
#if defined(SWIGRUBY)
  /*
   * Document-method: each_key
   * Iterate over each key
   */
  void each_key()
  {
    int i;
    for (i = 1; i < $self->nkeys; ++i ) {
      rb_yield( SWIG_NewPointerObj((void*) xrepokey_new( $self->keys + i, $self->repo, $self ), SWIGTYPE_p__Repokey, 0) );
    }
  }
#endif
#if defined(SWIGPYTHON)
    %pythoncode %{
        def keys(self):
          r = range(0,self.keysize())
          while r:
            yield self.key(r.pop(0))
    %}
#endif
}

