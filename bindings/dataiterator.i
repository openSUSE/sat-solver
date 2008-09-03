/*
 * Dataiterator
 */

%nodefault _Dataiterator;
%rename(Dataiterator) _Dataiterator;
typedef struct _Dataiterator {} Dataiterator;


%extend Dataiterator {
  %constant int SEARCH_STRINGMASK = SEARCH_STRINGMASK;
  %constant int SEARCH_STRING = SEARCH_STRING;
  %constant int SEARCH_SUBSTRING = SEARCH_SUBSTRING;
  %constant int SEARCH_GLOB = SEARCH_GLOB;
  %constant int SEARCH_REGEX = SEARCH_REGEX;

  %constant int SEARCH_NOCASE = SEARCH_NOCASE;
  %constant int SEARCH_NO_STORAGE_SOLVABLE = SEARCH_NO_STORAGE_SOLVABLE;
  %constant int SEARCH_EXTRA = SEARCH_EXTRA;
  %constant int SEARCH_ALL_REPOS = SEARCH_ALL_REPOS;
  %constant int SEARCH_SKIP_KIND = SEARCH_SKIP_KIND;

/* By default we don't match in attributes representing filelists
   because the construction of those strings is costly.  Specify this
   flag if you want this.  In that case kv->str will contain the full
   filename (if matched of course).  */
  %constant int SEARCH_FILES = SEARCH_FILES;

  Dataiterator(Repo *repo, const char *match, int option, Id p = 0, Id keyname = 0)
  {
    Dataiterator *di = calloc(1, sizeof( Dataiterator ));
    dataiterator_init(di, repo, p, keyname, match, option);
    return di;
  }
  
  ~Dataiterator() { free( $self ); }

  XSolvable *solvable()
  {
    return xsolvable_new( $self->repo->pool, self->solvid );
  }

  const char *key()
  {
    return id2str($self->repo->pool, $self->key->name);
  }

  const char *value()
  {
    if ($self->key->type == REPOKEY_TYPE_ID)
      return id2str($self->repo->pool, $self->kv.id );
    return "<internal>";
  }
  
  int step()
  {
    return dataiterator_step( $self );
  }
  
  int match(const char *value, int flags)
  {
    return dataiterator_match($self, flags, value);
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
  
  void jump_to_solvable(XSolvable *xs)
  {
    dataiterator_jump_to_solvable($self, xsolvable_solvable(xs));
  }
  
  void jump_to_repo(Repo *repo)
  {
    dataiterator_jump_to_repo($self, repo);
  }
}

