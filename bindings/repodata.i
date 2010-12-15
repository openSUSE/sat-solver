/*
 * Document-class: Repodata
 * Repodata holds additional Solvable attributes which are not
 * required for dependency solving.
 *
 * Repodata is a Repo extension and thus belongs to a Repo.
 *
 * === Constructor
 * There is no way to create a Repodata on its own, it can only be accessed
 * through Pool.data
 *
 */

%nodefault _Repodata;
%rename(Repodata) _Repodata;
typedef struct _Repodata {} Repodata;

%extend Repodata {
  
  /*
   * number of keys in this Repodata
   */
  int size()
  { return $self->nkeys-1; } /* key 0 is reserved */

#if defined(SWIGRUBY)
  %alias key "[]";
#endif
  /*
   * access Repokey by index
   *
   * call-seq:
   *   repodata[42] -> Repokey
   *   repodata.get(42) -> Repokey
   *
   */
  XRepokey *key( int i )
  {
    if (i >= 0 && i < $self->nkeys-1)
      return xrepokey_new( $self->keys + i + 1, $self->repo, $self ); /* key 0 is reserved */
    return NULL;
  }
  
#if defined(SWIGRUBY)
  /*
   * Iterate over each key
   *
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
          r = range(0,self.size())
          while r:
            yield self.key(r.pop(0))
    %}
#endif
#if defined(SWIGPERL)
  const XRepokey **keys()
  {
    PtrIndex pi;
    NewPtrIndex(pi,const XRepokey **,0);
    int i;
    for (i = 1; i < $self->nkeys; ++i ) {
      AddPtrIndex((&pi),const XRepokey **,xrepokey_new( $self->keys + i, $self->repo, $self ));
    }
    ReturnPtrIndex(pi,const XRepokey **);
  }
#endif
}
