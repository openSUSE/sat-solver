/*
 * Document-class: Dataiterator
 * This class represents an _Iterator_ for Solvable attributes.
 *
 * === Usage
 *
 * The Dataiterator is the block argument for calls to +search+
 * which is defined for Pool (search whole Pool) and Repository (limit
 * search to Repository)
 *
 * === Example code
 *
 * - Search for exact string match in Pool
 *
 *    pool.search("yast2", Satsolver::SEARCH_STRING) do |di|
 *      puts "#{di.solvable} matches 'yast2' in #{di.key.name}:  #{di.value}"
 *    end
 *
 * - Search for exact file match in Pool
 *
 *    pool.search("/usr/bin/python", Satsolver::SEARCH_STRING|Satsolver::SEARCH_FILES) do |d|
 *      puts "#{d.solvable} matches '/usr/bin/python' in #{d.key.name}: #{d.value}"
 *    end
 *
 * - Search for exact file match in Repository
 *
 *    repo.search("/usr/bin/python", Satsolver::SEARCH_STRING|Satsolver::SEARCH_FILES) do |d|
 *      puts "#{d.solvable} matches '/usr/bin/python' in #{d.key.name}: #{d.value}"
 *    end
 *
 */

%nodefault _Dataiterator;
%rename(Dataiterator) _Dataiterator;
typedef struct _Dataiterator {} Dataiterator;

%extend Dataiterator {
  %constant int SEARCH_STRINGMASK = SEARCH_STRINGMASK;
  /* search for exact string match */
  %constant int SEARCH_STRING = SEARCH_STRING;
  /* search for substring match */
  %constant int SEARCH_SUBSTRING = SEARCH_SUBSTRING;
  /* search for glob */
  %constant int SEARCH_GLOB = SEARCH_GLOB;
  /* search for regexp. _Caution_ this is slow */
  %constant int SEARCH_REGEX = SEARCH_REGEX;
  %constant int SEARCH_ERROR = SEARCH_ERROR;

  /* ignore case in matches */
  %constant int SEARCH_NOCASE = SEARCH_NOCASE;
  %constant int SEARCH_NO_STORAGE_SOLVABLE = SEARCH_NO_STORAGE_SOLVABLE;
  %constant int SEARCH_SUB = SEARCH_SUB;
  %constant int SEARCH_ARRAYSENTINEL = SEARCH_ARRAYSENTINEL;
  %constant int SEARCH_SKIP_KIND = SEARCH_SKIP_KIND;

  /* By default we don't match in attributes representing filelists
   * because the construction of those strings is costly.  Specify this
   * flag if you want this.  In that case kv->str will contain the full
   * filename (if matched of course).
   */
  %constant int SEARCH_FILES = SEARCH_FILES;

  /*
   * Complete Dataiterator constructor, to be used via %python in Swig
   */

  Dataiterator(Pool *pool, Repo *repo, const char *match, int option, XSolvable *xs = 0, const char *keyname = 0)
  {
    return swig_dataiterator_new(pool, repo, match, option, xs, keyname);
  }
  
  ~Dataiterator() { swig_dataiterator_free($self); }

  /* return the matching Solvable
   */
  XSolvable *solvable()
  {
    return xsolvable_new( $self->repo->pool, $self->solvid );
  }

  /*
   * return corresponding Repokey, if defined
   *
   * internal attributes, like solvable.name, don't have an
   * explicit Repokey
   */
  XRepokey *key()
  {
    return xrepokey_new($self->key, $self->repo, $self->data);
  }

  /* keyname of the match
   */
  const char *keyname()
  {
    return id2str($self->repo->pool, $self->key->name);
  }

  /* Document-method: value
   * Return value of matching attribute
   * The type of the value (i.e Integer, String, Array, ...) depends on the matching keyname
   */
#if defined(SWIGPYTHON)
  PyObject *
#endif
#if defined(SWIGRUBY)
  VALUE
#endif
#if defined(SWIGPERL)
  SV *
#endif
    value()
  {
    Swig_Type value = dataiterator_value($self);
#if defined(SWIGPYTHON)
    Py_INCREF(value);
#endif
    return value;
  }

  /*
   * iterator step
   *
   * increments the Dataiterator to the next match
   */  
  int step()
  {
    return dataiterator_step( $self );
  }
  
  void skip_attr()
  {
    dataiterator_skip_attribute($self);
  }
  
  void skip_solvable()
  {
    dataiterator_skip_solvable($self);
  }
  
  void skip_repo()
  {
    dataiterator_skip_repo($self);
  }
  
  /* position Dataiterator at a specific solvable
   */
  void jump_to_solvable(XSolvable *xs)
  {
    dataiterator_jump_to_solvid($self, xs->id);
  }

  /* position Dataiterator at a specific Repository
   */ 
  void jump_to_repo(Repo *repo)
  {
    dataiterator_jump_to_repo($self, repo);
  }
}

