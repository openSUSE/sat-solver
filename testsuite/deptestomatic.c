/*  -*- mode: C; c-file-style: "gnu"; fill-column: 78 -*- */
/*
 * deptestomatic.c
 *
 * Parse 'deptestomatic' XML representation
 * and run test case
 *
 */

#include <sys/types.h>
#include <unistd.h>
#include <fnmatch.h>
#include <limits.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <expat.h>
#include <libgen.h>
#include <dirent.h>

#include "solver.h"
#include "repo_solv.h"
#include "poolarch.h"
#include "evr.h"

static int verbose = 0;
static int redcarpet = 0;

static const char *Current;

#define MAXNAMELEN 100

static void
err( const char *msg, ...)
{
  va_list ap;
  va_start( ap, msg );
  fprintf( stderr, "%s: ", Current );
  vfprintf( stderr, msg, ap );
  fprintf( stderr, "\n" );
  va_end( ap );
}

/* XML parser states */

enum state {
  STATE_START,
  STATE_TEST,
  STATE_SETUP,
  STATE_ARCH,
  STATE_SYSTEM,
  STATE_CHANNEL,
  STATE_FORCE,
  STATE_LOCALE,
  STATE_FORCEINSTALL,
  STATE_FORCEUNINSTALL,
  STATE_LOCK,
  STATE_KEEP,
  STATE_MEDIAID,
  STATE_MEDIAORDER,
  STATE_TRIAL,
  STATE_INSTALL,
  STATE_REMOVE,
  STATE_REPORTPROBLEMS,
  STATE_TAKESOLUTION,
  STATE_ESTABLISH,
  STATE_SHOWPOOL,
  STATE_DISTUPGRADE,
  STATE_ADDREQUIRE,
  STATE_ADDCONFLICT,
  STATE_CURRENT,
  STATE_SUBSCRIBE,
  STATE_VERIFY,
  STATE_UPGRADE,
  STATE_TRANSACT,
  STATE_HARDWAREINFO,
  STATE_SETLICENSEBIT,
  STATE_INSTORDER,
  STATE_AVAILABLELOCALES,
  NUMSTATES
};

#define PACK_BLOCK 255

struct stateswitch {
  enum state from;
  char *ename;
  enum state to;
  int docontent;
};

static struct stateswitch stateswitches[] = {
  { STATE_START,       "test",         STATE_TEST, 0 },

  { STATE_TEST,        "setup",        STATE_SETUP, 0 },
  { STATE_TEST,        "trial",        STATE_TRIAL, 0 },

  { STATE_SETUP,       "arch",         STATE_ARCH, 0 },
  { STATE_SETUP,       "system",       STATE_SYSTEM, 0 },
  { STATE_SETUP,       "channel",      STATE_CHANNEL, 0 },
  { STATE_SETUP,       "forceresolve", STATE_FORCE, 0 },
  { STATE_SETUP,       "forceResolve", STATE_FORCE, 0 },
  { STATE_SETUP,       "locale",       STATE_LOCALE, 0 },
  { STATE_SETUP,       "force-install",STATE_FORCEINSTALL, 0 },
  { STATE_SETUP,       "force-uninstall",STATE_FORCEUNINSTALL, 0 },
  { STATE_SETUP,       "lock",         STATE_LOCK, 0 },
  { STATE_SETUP,       "mediaid",      STATE_MEDIAID, 0 },
  { STATE_SETUP,       "hardwareInfo", STATE_HARDWAREINFO, 0 },
  { STATE_SETUP,       "setlicencebit", STATE_SETLICENSEBIT, 0 },

  { STATE_TRIAL,       "install",      STATE_INSTALL, 0 },
  { STATE_TRIAL,       "uninstall",    STATE_REMOVE, 0 },
  { STATE_TRIAL,       "distupgrade",  STATE_DISTUPGRADE, 0 },
  { STATE_TRIAL,       "addRequire",   STATE_ADDREQUIRE, 0 },
  { STATE_TRIAL,       "addConflict",  STATE_ADDCONFLICT, 0 },
  { STATE_TRIAL,       "reportproblems", STATE_REPORTPROBLEMS, 0 },
  { STATE_TRIAL,       "takesolution", STATE_TAKESOLUTION, 0 },
  { STATE_TRIAL,       "establish",    STATE_ESTABLISH, 0 },
  { STATE_TRIAL,       "showpool",     STATE_SHOWPOOL, 0 },
  { STATE_TRIAL,       "current",      STATE_CURRENT, 0 },
  { STATE_TRIAL,       "subscribe",    STATE_SUBSCRIBE, 0 },
  { STATE_TRIAL,       "verify",       STATE_VERIFY, 0 },
  { STATE_TRIAL,       "upgrade",      STATE_UPGRADE, 0 },
  { STATE_TRIAL,       "lock",         STATE_LOCK, 0 },
  { STATE_TRIAL,       "transact",     STATE_TRANSACT, 0 },
  { STATE_TRIAL,       "mediaorder",   STATE_MEDIAORDER, 0 },
  { STATE_TRIAL,       "instorder",    STATE_INSTORDER, 0 },
  { STATE_TRIAL,       "availablelocales",STATE_AVAILABLELOCALES, 0 },
  { STATE_TRIAL,       "keep",         STATE_KEEP, 0 },

  { NUMSTATES }

};

/*
 * parser data
 */

struct _channelmap {
  Id nid;
  char *name;
  Repo *repo;
};

typedef struct _parsedata {
  // XML parser data
  int depth;
  enum state state;	// current state
  int statedepth;		       /* deepness of state */

  char *content;	// buffer for content of node
  int lcontent;		// actual length of current content
  int acontent;		// actual buffer size
  int docontent;	// handle content

  Queue trials;

  Pool *pool;		// current pool, with channels

  int nchannels;
  struct _channelmap *channels;

  Repo *system;	// system repo
  Repo *locales;      // where we store locales

  Id arch;              // set architecture

  int fixsystem;                 /* 0/1, if fix system (?) */
  int updatesystem;              /* 0/1, if solver should update system */
  int allowdowngrade;            /* 0/1, if version downgrades are allowed */
  int allowuninstall;            /* 0/1, if solver should remove installed package for solution */ 
  int allowvirtualconflicts;     /* 0/1, if conflicts specify package names or package provides */
  int allowarchchange;           /* 0/1, if packages can change architecture */

  struct stateswitch *swtab[NUMSTATES];
  enum state sbtab[NUMSTATES];
  char directory[PATH_MAX];

  char *hardwareinfo;
  char **modaliases;
  int nmodaliases;
} Parsedata;


static void
add_modalias(Parsedata *pd, const char *s)
{
  if ((pd->nmodaliases & 15) == 0)
    {
      if (pd->modaliases == 0)
	pd->modaliases = malloc(16 * sizeof(char *));
      else
	pd->modaliases = realloc(pd->modaliases, (pd->nmodaliases + 16) * sizeof(char *));
    }
  pd->modaliases[pd->nmodaliases++] = strdup(s);
}

static void
collect_modaliases(Parsedata *pd, int depth, char *dir, char *edir)
{
  if (depth == 0)
    {
      strcpy(edir, "/bus");
      collect_modaliases(pd, 1, dir, edir + 4);
      *edir = 0;
      return;
    }
  if (depth == 1 || depth == 3)
    {
      struct dirent *de;
      DIR *di = opendir(dir);
      if (!di)
	return;
      while ((de = readdir(di)) != 0)
	{
	  if (de->d_name[0] == '.')
	    continue;
	  *edir = '/';
	  strcpy(edir + 1, de->d_name);
	  collect_modaliases(pd, depth + 1, dir, edir + strlen(edir));
	  *edir = 0;
	}
      closedir(di);
      return;
    }
  if (depth == 2)
    {
      strcpy(edir, "/devices");
      collect_modaliases(pd, 3, dir, edir + 8);
      *edir = 0;
      return;
    }
  if (depth == 4)
    {
      int fd, l;
      char buf[PATH_MAX];

      strcpy(edir, "/modalias");
      if ((fd = open(dir, O_RDONLY)) == -1)
	return;
      l = read(fd, buf, sizeof(buf));
      close(fd);
      if (l == 0 || l == sizeof(buf))
	return;
      if (buf[l - 1] == '\n')
	l--;
      if (l == 0)
	return;
      buf[l] = 0;
      add_modalias(pd, buf);
    }
}

static Id
nscallback(Pool *pool, void *data, Id name, Id evr)
{
  Parsedata *pd = data;
  const char *match;
  char **m;
  char dir[PATH_MAX];
  int i;

  if (name != NAMESPACE_MODALIAS || ISRELDEP(evr))
    return 0;
  if (pd->nmodaliases == -1)
    return 0;
  if (!pd->modaliases)
    {
      if (!pd->hardwareinfo)
	{
	  return 0;
	  // strcpy(dir, "/sys");
	}
      else
	strcpy(dir, pd->hardwareinfo);
      collect_modaliases(pd, 0, dir, dir + strlen(dir));
      if (pd->nmodaliases == 0)
	{
	  pd->nmodaliases = -1;
	  return 0;
	}
    }
  match = id2str(pool, evr);
  for (i = 0, m = pd->modaliases; i < pd->nmodaliases; i++, m++)
    if (fnmatch(match, *m, 0))
      return 1;
  return 0;
}



/*------------------------------------------------------------------*/
/* attribute handling */

/*
 * return value of attname
 * or NULL if not found
 */

static const char *
attrval( const char **atts, const char *attname )
{
  for (; *atts; atts += 2) {
    if (!strcmp( *atts, attname )) {
      return atts[1];
    }
  }
  return NULL;
}

/*------------------------------------------------------------------*/
/* E:V-R handling */

#if 0
// create Id from epoch:version-release

static Id
evr2id( Pool *pool, Parsedata *pd, const char *e, const char *v, const char *r )
{
  char *c;
  int l;

  // treat explitcit 0 as NULL
  if (e && !strcmp(e, "0"))
    e = NULL;

  if (v && !e)
    {
      const char *v2;
      // scan version for ":"
      for (v2 = v; *v2 >= '0' && *v2 <= '9'; v2++)	// skip leading digits
        ;
      // if version contains ":", set epoch to "0"
      if (v2 > v && *v2 == ':')
	e = "0";
    }

  // compute length of Id string
  l = 1;  // for the \0
  if (e)
    l += strlen(e) + 1;  // e:
  if (v)
    l += strlen(v);      // v
  if (r)
    l += strlen(r) + 1;  // -r

  // extend content if not sufficient
  if (l > pd->acontent)
    {
      pd->content = (char *)realloc( pd->content, l + 256 );
      pd->acontent = l + 256;
    }

  // copy e-v-r to content
  c = pd->content;
  if (e)
    {
      strcpy( c, e );
      c += strlen(c);
      *c++ = ':';
    }
  if (v)
    {
      strcpy( c, v );
      c += strlen(c);
    }
  if (r)
    {
      *c++ = '-';
      strcpy( c, r );
      c += strlen(c);
    }
  *c = 0;
  // if nothing inserted, return Id 0
  if (!*pd->content)
    return ID_NULL;
#if 0
  fprintf(stderr, "evr: %s\n", pd->content);
#endif
  // intern and create
  return str2id( pool, pd->content, 1 );
}


// create e:v-r from attributes
// atts is array of name,value pairs, NULL at end
//   even index into atts is name
//   odd index is value
//
static Id
evr_atts2id(Pool *pool, Parsedata *pd, const char **atts)
{
  const char *e, *v, *r;
  e = v = r = 0;
  for (; *atts; atts += 2)
    {
      if (!strcmp( *atts, "epoch") )
	e = atts[1];
      else if (!strcmp( *atts, "version") )
	v = atts[1];
      else if (!strcmp( *atts, "release") )
	r = atts[1];
    }
  return evr2id( pool, pd, e, v, r );
}

#endif

/*------------------------------------------------------------------*/
/* rel operator handling */
#if 0
struct flagtab {
  char *from;
  int to;
};

static struct flagtab flagtab[] = {
  { ">",  REL_GT },
  { "=",  REL_EQ },
  { ">=", REL_GT|REL_EQ },
  { "<",  REL_LT },
  { "!=", REL_GT|REL_LT },
  { "<=", REL_LT|REL_EQ },
  { "(any)", REL_LT|REL_EQ|REL_GT },
  { "==", REL_EQ },
  { "gt", REL_GT },
  { "eq", REL_EQ },
  { "ge", REL_GT|REL_EQ },
  { "lt", REL_LT },
  { "ne", REL_GT|REL_LT },
  { "le", REL_LT|REL_EQ },
  { "GT", REL_GT },
  { "EQ", REL_EQ },
  { "GE", REL_GT|REL_EQ },
  { "LT", REL_LT },
  { "NE", REL_GT|REL_LT },
  { "LE", REL_LT|REL_EQ }
};

/*
 * process new dependency from parser
 *  olddeps = already collected deps, this defines the 'kind' of dep
 *  atts = array of name,value attributes of dep
 *  isreq == 1 if its a requires
 */

static Id
adddep( Pool *pool, Parsedata *pd, unsigned int olddeps, const char **atts, int isreq )
{
  Id id, name;
  const char *n, *f, *k;
  const char **a;

  n = f = k = NULL;

  /* loop over name,value pairs */
  for (a = atts; *a; a += 2)
    {
      if (!strcmp( *a, "name" ))
	n = a[1];
      if (!strcmp( *a, "kind" ))
	k = a[1];
      else if (!strcmp( *a, "op" ))
	f = a[1];
      else if (isreq && !strcmp( *a, "pre" ) && a[1][0] == '1')
        isreq = 2;
    }
  if (!n)			       /* quit if no name found */
    return olddeps;

  /* kind, name */
  if (k && !strcmp(k, "package"))
    k = NULL;			       /* package is default */

  if (k)			       /* if kind!=package, intern <kind>:<name> */
    {
      int l = strlen(k) + 1 + strlen(n) + 1;
      if (l > pd->acontent)	       /* extend buffer if needed */
	{
	  pd->content = (char *)realloc( pd->content, l + 256 );
	  pd->acontent = l + 256;
	}
      sprintf( pd->content, "%s:%s", k, n );
      name = str2id( pool, pd->content, 1 );
    }
  else
    name = str2id( pool, n, 1 );       /* package: just intern <name> */

  if (f)			       /* operator ? */
    {
      /* intern e:v-r */
      Id evr = evr_atts2id( pool, pd, atts );
      /* parser operator to flags */
      int flags;
      for (flags = 0; flags < sizeof(flagtab)/sizeof(*flagtab); flags++)
	if (!strcmp( f, flagtab[flags].from) )
	  {
	    flags = flagtab[flags].to;
	    break;
	  }
      if (flags > 7)
	flags = 0;
      /* intern rel */
      id = rel2id( pool, name, evr, flags, 1 );
    }
  else
    id = name;			       /* no operator */

  return id;
}

#endif

/*----------------------------------------------------------------*/

/*
 * read repo from file as name
 *
 */

static Repo *
add_repo( Parsedata *pd, const char *name, const char *file )
{
  if (!file)
    {
      err( "add_repo, no filename!" );
      return NULL;
    }
  char solvname[256];
  int l = strlen( file );
  if (l > 255 )
    {
      err( "add_repo, filename too long!" );
      return NULL;
    }

  const char *ptr = file + l - 1;
  while (*ptr)
    {
      if (ptr == file)
	break;
      if (*ptr == '.')
	{
	  if (!strncmp( ptr, ".xml", 4 )) {
	    l = ptr - file;
	    break;
	  }
	}
      --ptr;
    }
  strncpy( solvname, file, l );
  strcpy( solvname + l, ".solv" );

  if (verbose) err( "%s:%s -> %s", name, file, solvname );
  FILE *fp = fopen( solvname, "r" );
  if (!fp)
    {
      perror( solvname );
      return NULL;
    }
  Repo *s = pool_addrepo_solv( pd->pool, fp, name );
  fclose( fp );
  return s;
}


// find solvable id by name and repo
//   If repo != NULL, find there
//   else find in pool (available packages)
//

static Id
select_solvable( Pool *pool, Repo *repo, const char *name, const char *version, const char *arch )
{
  Id id, archid;
  int i, end;

  id = str2id( pool, name, 0 );
  if (id == ID_NULL) {
    return id;
  }
  archid = ID_NULL;
  if (arch)
    {
      archid = str2id( pool, arch, 0 );
      if (archid == ID_NULL) {
        return ID_NULL;
      }
    }

  i = repo ? repo->start : 1;
  end = repo ? repo->start + repo->nsolvables : pool->nsolvables;
  for (; i < end; i++)
    {
      if (archid && pool->solvables[i].arch != archid)
	continue;
      if (pool->solvables[i].name != id)
	continue;
      if (version)
	{
	  const char *sver = id2str(pool, pool->solvables[i].evr);
	  const char *svere = strrchr(sver, '-');
	  if (vercmp(version, version + strlen(version), sver, svere ? svere : sver + strlen(sver)))
	    continue;
	}
      return i;
    }

  return ID_NULL;
}

static void getPackageName( const char **atts, char package[] )
{
  package[0] = 0;
  const char *packattr = attrval( atts, "package" );
  const char *kind     = attrval( atts, "kind" );

  if (packattr == NULL)
    packattr = attrval( atts, "name" );

  /* for non-packages we prepend the namespace */
  if (kind != NULL && strcmp(kind, "package") )
    {
      strncpy(package, kind, MAXNAMELEN);
      strncat(package, ":" , MAXNAMELEN);
    }

  if (packattr)
    strncat(package, packattr, MAXNAMELEN);
}


static void insertLocale( Parsedata *pd, const char *name)
{
  Pool *pool = pd->pool;
  Solvable *s;
  Id id;
  char locale[MAXNAMELEN];
  int i;

  if (!pd->locales) 
    {
      pd->nchannels++;
      pd->channels = (struct _channelmap *)realloc( pd->channels, pd->nchannels * sizeof( struct _channelmap ) );
      struct _channelmap *cmap = pd->channels + (pd->nchannels-1);

      cmap->repo = pd->locales = pool_addrepo_empty(pool);
      pd->locales->name = cmap->name = strdup( "locales" );
      cmap->nid = str2id( pd->pool, cmap->name, 1 );
    }

  strcpy(locale, "language:");
  strncat(locale, name, MAXNAMELEN);
  id = str2id(pool, locale, 1);

  /* check if we already have that one */
  for (i = pd->locales->start; i < pd->locales->start + pd->locales->nsolvables; i++)
    if (pool->solvables[i].name == id)
      return;
  
  pool->solvables = realloc(pool->solvables, (pool->nsolvables + 1) * sizeof(Solvable));
  s = pool->solvables + pool->nsolvables++;
  pd->locales->nsolvables++;
  memset(s, 0, sizeof(Solvable));
  s->repo = pd->locales;
  s->name = id;
  s->arch = ARCH_NOARCH;
  s->evr = ID_EMPTY;
  s->provides = repo_addid_dep(pd->locales, s->provides, id, 0);

  queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE );
  queue_push( &(pd->trials), s - pool->solvables );
}

/*----------------------------------------------------------------*/

/*
 * XML callback
 * <name>
 *
 */

static void XMLCALL
startElement( void *userData, const char *name, const char **atts )
{
  Parsedata *pd = (Parsedata *)userData;
  struct stateswitch *sw;
  Pool *pool = pd->pool;

//  fprintf( stderr, "startElement <%s>, depth %d, statedepth %d", name, pd->depth, pd->statedepth );

  if (pd->depth != pd->statedepth)
    {
      pd->depth++;
      return;
    }

  pd->depth++;

  /* find node name in stateswitch */
  for (sw = pd->swtab[pd->state]; sw->from == pd->state; sw++)
  {
    if (!strcmp( sw->ename, name ))
      break;
  }

  /* check if we're at the right level */
  if (sw->from != pd->state)
    {
#if 1
      err( "%s: into unknown: %s", Current, name );
#endif
      return;
    }

  // set new state
  pd->state = sw->to;

  pd->docontent = sw->docontent;
  pd->statedepth = pd->depth;

  // start with empty content
  // (will collect data until end element
  pd->lcontent = 0;
  *pd->content = 0;

  const char *val;
  switch( pd->state )
    {
     case STATE_TEST: {
      val = attrval( atts, "allow_virtual_conflicts" );
      if (val && !strcmp( val, "yes" ) )
	pd->allowvirtualconflicts = 1;
     }
     break;

      /*-----------------------------------------------------------*/
      /* <setup> stuff */

    case STATE_SETUP: {		       /* setup test, with optional arch */
      val = attrval( atts, "arch" );
      if (val) {
	if (pd->arch) {
	  err( "<setup> overrides arch" );
	}
	pd->arch = str2id( pool, val, 1 );
      }
    }
    break;

    case STATE_ARCH: {		       /* set architecture */
      val = attrval( atts, "name" );
      if (!val)
	err( "<arch> without name" );
      else
        {
          if (pd->arch)
	  err( "<arch> overrides arch" );
	pd->arch = str2id( pool, val, 1 );
      }
    }
    break;

    case STATE_CHANNEL: 	       /* read channel */
      {
	const char *name = attrval( atts, "name" );
	const char *file = attrval( atts, "file" );
	if (file) 
	  {
	    char path[PATH_MAX];
	    strncpy(path, pd->directory, sizeof(path));
	    strncat(path, file, sizeof(path));

	    if (!name)
	      name = file;

	    char *cname = strdup( name );
	    Repo *repo = add_repo( pd, cname, path );
	    if (repo) 
	      {
		pd->nchannels++;
		pd->channels = (struct _channelmap *)realloc( pd->channels, pd->nchannels * sizeof( struct _channelmap ) );
		if (pd->channels == NULL) 
		  {
		    err( "OOM!" );
		    abort();
		  }
		struct _channelmap *cmap = pd->channels + (pd->nchannels-1);
		cmap->name = cname;
		cmap->nid = str2id( pool, cname, 1 );
		cmap->repo = repo;
	      }
	    else 
	      {
		free( cname );
		err( "Can't add <channel> %s", name );
		exit( 1 );
	      }

	  }
	else 
	  {
	    err( "<channel> incomplete" );
	    exit( 1 );
	  }
      }
    break;

    case STATE_SYSTEM: 	       /* system file */
      {
	const char *file = attrval( atts, "file" );
	if (pd->system)
	  err( "Duplicate <system>" );
     
	if (file) 
	  {
	    char path[PATH_MAX];
	    strncpy(path, pd->directory, sizeof(path));
	    strncat(path, file, sizeof(path));
	    Repo *repo = add_repo( pd, "system", path );
	    if (repo)
	      pd->system = repo;
	    else 
	      {
		err( "Can't add <system>" );
		exit( 1 );
	      }
	  }
	else 
	  {
	    err( "<system> incomplete" );
	    exit( 1 );
	  }
      }
      break;

    case STATE_LOCALE: /* system locales */
      {	       

	const char *name = attrval( atts, "name" );

	const char *sep1 = strchr(name, '@');
	const char *sep2 = strchr(name, '.');
      
	char locale[MAXNAMELEN];
	if (!sep1 && !sep2)
	  {
	    strncpy(locale, name, sizeof(locale));
	  } 
	else 
	  {
	    const char * first = sep1;
	    if (sep2 && sep1 && sep2 < sep1)
	      first = sep2;
	    if (name - first >= sizeof(locale))
	      {
		err("locale argument insane");
		exit(1);
	      }
	    strncpy(locale, name, name - first);
	    locale[first-name] = 0;
	  }

	insertLocale(pd, locale);

	sep1 = strchr(locale, '_'); // reuse of variable
	if ( sep1 ) 
	  {
	    // insert the language only too
            if (!strcmp(locale, "pt_BR"))
	      {
		insertLocale(pd, "en");
	      }
            else 
	      {
		locale[sep1-locale] = 0;
		insertLocale( pd, locale );
	      }
	  } 
      }
      break;

    case STATE_FORCE:		       /* force solution by evtl. removing system packages */
      pd->allowuninstall = 1;
      break;

    case STATE_FORCEINSTALL:	       /* pretend its installed */
      break;

    case STATE_FORCEUNINSTALL:	       /* pretend its not installed */
      break;

    case STATE_LOCK: 	               /* prevent install/removal */
      {
	/*
	 * <lock channel="1" package="foofoo" />
	 */

	const char *channel = attrval( atts, "channel" );
	char package[MAXNAMELEN];
	getPackageName( atts, package );
	const char *arch = attrval( atts, "arch" );
	const char *version = attrval( atts, "version" );

	if (!strlen(package))
	  {
	    err( "%s: No package given in <lock>", Current );
	    break;
	  }

	Repo *repo = NULL;
	if (channel) 		       /* from specific channel */
	  {
	    Id cid = str2id( pool, channel, 0 );
	    if (cid != ID_NULL) 
	      {
		int i = 0;
		while (i < pd->nchannels ) 
		  {
		    if (pd->channels[i].nid == cid) 
		      {
			repo = pd->channels[i].repo;
			break;
		      }
		    ++i;
		  }
	      }
	  }
	if (repo)
	  {
	    Id id = select_solvable( pool, repo, package, version, arch );
	    if (id == ID_NULL) 
	      {
		err( "Install: Package '%s' not found", package );
		if (repo) err( " in channel '%s'", channel );
		exit( 1 );
	      }
	    queue_push( &(pd->trials), SOLVER_ERASE_SOLVABLE );
	    queue_push( &(pd->trials), id );
	  }
	else 			       /* no channel given, lock installed */
	  {
	    Id id = select_solvable( pool, pd->system, package, version, arch );
	    queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE );
	    queue_push( &(pd->trials), id );
	  }
      }
      break;

    case STATE_MEDIAORDER:
    case STATE_MEDIAID:		       /* output installation order with media id */
    break;

    case STATE_HARDWAREINFO:
      {
	if (pd->hardwareinfo)
	  free((char *)pd->hardwareinfo);

        const char *dir = attrval( atts, "path" );
printf("hardware %s\n", dir);
	if (dir)
	  {
	    char path[PATH_MAX];
	    strncpy(path, pd->directory, sizeof(path));
	    strncat(path, dir, sizeof(path));
	    pd->hardwareinfo = strdup(path);
            printf("Setting hardwareinfo to %s\n", path);
	  } 
	else
	  pd->hardwareinfo = 0;
      }
    break;
      
      /*-----------------------------------------------------------*/
      /* <trial> stuff */

     case STATE_TRIAL:
      break;

    case STATE_INSTALL: 	       /* install package */
      {
	/*
	 * <install channel="1" package="foofoo" />
	 * <install channel="1" kind="package" name="foofoo" arch="i586" version="2.60" release="21"/>
	 */

	const char *channel = attrval( atts, "channel" );
	const char *arch = attrval( atts, "arch" );
        const char *version = attrval( atts, "version" );
	char package[MAXNAMELEN];
	getPackageName( atts, package );

	if (!strlen(package))
	  {
	    err( "%s: No package given in <install>", Current );
	    break;
	  }

	Repo *repo = NULL;
	if (channel) /* from specific channel */
	  {
	    Id cid = str2id( pool, channel, 0 );
	    if (cid == ID_NULL)
	      {
		err( "Install: Channel '%s' does not exist", channel );
		exit( 1 );
	      }
	    int i = 0;
	    while (i < pd->nchannels ) 
	      {
		if (pd->channels[i].nid == cid) 
		  {
		    repo = pd->channels[i].repo;
		    break;
		  }
		++i;
	      }
	    Id id = select_solvable( pool, repo, package, version, arch );
	    if (id == ID_NULL) 
	      {
		err( "Install: Package '%s' not found", package );
		if (repo) err( " in channel '%s'", channel );
		exit( 1 );
	      }
	    queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE );
	    queue_push( &(pd->trials), id );
	  }
	else 			       /* no channel given, from any channel */
	  {
	    Id id = str2id( pool, package, 1 );
	    queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE_PROVIDES );
	    queue_push( &(pd->trials), id );
	  }
      }
      break;

    case STATE_REMOVE: 	       /* remove package */
      {
	char package[MAXNAMELEN];
	getPackageName( atts, package );

	if (!strlen(package))
	  {
	    err( "No package given in <uninstall>" );
	    exit( 1 );
	  }
	if (pd->system == NULL) 
	  {
	    err( "No system channel defined to <uninstall> from" );
	    exit( 1 );
	  }
	Id id = select_solvable( pool, pd->system, package, 0, 0 );
	if (id == ID_NULL) 
	  {
	    err( "Remove: Package '%s' is not installed", package );
	    exit(1);
	  }
	id = str2id( pool, package, 0 );
	queue_push( &(pd->trials), SOLVER_ERASE_SOLVABLE_NAME );
	queue_push( &(pd->trials), id);
      }
      break;

    case STATE_REPORTPROBLEMS:
    break;

    case STATE_ESTABLISH:
    break;

    case STATE_AVAILABLELOCALES:
    break;

    case STATE_INSTORDER:
    break;

    case STATE_SHOWPOOL:
    break;

    case STATE_ADDREQUIRE: {
      const char *name = attrval( atts, "name" );
      if (name == NULL) {
	err( "No name given in <addrequire>" );
	exit( 1 );
      }
      queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE_PROVIDES );
      queue_push( &(pd->trials), str2id( pd->pool, name, 1 ) );
    }
    break;

    case STATE_ADDCONFLICT: {
      const char *name = attrval( atts, "name" );
      if (name == NULL) {
	err( "No name given in <addconflict>" );
	exit( 1 );
      }
      queue_push( &(pd->trials), SOLVER_ERASE_SOLVABLE_PROVIDES );
      queue_push( &(pd->trials), str2id( pd->pool, name, 1 ) );
    }
    break;

    case STATE_CURRENT: {	       /* FIXME: needs repo prio */
//      const char *channel = attrval( atts, "channel" );
//      err( "ignoring <current channel=\"%s\">", channel );
    }
    break;

    case STATE_SUBSCRIBE: {	       /* FIXME: needs repo prio */
//      const char *channel = attrval( atts, "channel" );
//      err( "ignoring <subscribe channel=\"%s\">", channel );
    }
    break;

    case STATE_VERIFY: {
      pd->fixsystem = 1;
      // pd->allowuninstall = 1;
    }
    break;

    case STATE_DISTUPGRADE:
      pd->updatesystem = 1;
      pd->allowarchchange = 1;
      //pd->fixsystem = 1;
      pd->allowuninstall = 1;
      pd->allowdowngrade = 1;
      break;

    case STATE_UPGRADE: {
      pd->updatesystem = 1;
    }
    break;

    case STATE_KEEP: {
      const char *arch = attrval( atts, "arch" );
      const char *version = attrval( atts, "version" );
      char package[MAXNAMELEN];
      getPackageName( atts, package );

      if (!strlen(package))
        {
	err( "No package given in <keep>" );
	exit( 1 );
      }
      Id id = select_solvable( pool, pd->system, package, version, arch );
      queue_push( &(pd->trials), SOLVER_INSTALL_SOLVABLE );
      queue_push( &(pd->trials), id );
    }
    break;

    default:
      err( "%s: <%s> unhandled", Current, name );
      break;
    }
}


/*
 * XML callback
 * </name>
 *
 */

static void XMLCALL
endElement( void *userData, const char *name )
{
  Parsedata *pd = (Parsedata *)userData;
  Pool *pool = pd->pool;

//  err( "endElement </%s>, depth %d, statedepth %d", name, pd->depth, pd->statedepth );

  if (pd->depth != pd->statedepth)
    {
      pd->depth--;
      // printf("back from unknown %d %d %d", pd->state, pd->depth, pd->statedepth );
      return;
    }

  pd->depth--;
  pd->statedepth--;
  switch (pd->state)
    {

    case STATE_TRIAL: {		       /* trial complete */

      if (!pd->system)
	pd->system = pool_addrepo_empty( pd->pool );

      if (pd->arch)
        pool_setarch( pd->pool, id2str(pd->pool, pd->arch) );
      else
	pool_setarch( pd->pool, "i686" );

      pool_prepare( pd->pool );
      if (redcarpet)
        pool->promoteepoch = 1;

      Solver *solv = solver_create( pd->pool, pd->system );
      solv->fixsystem = pd->fixsystem;
      solv->updatesystem = pd->updatesystem;
      solv->allowdowngrade = pd->allowdowngrade;
      solv->allowuninstall = pd->allowuninstall;
      solv->allowarchchange = pd->allowarchchange;
      solv->rc_output = redcarpet ? 2 : 1;
      solv->noupdateprovide = 1;
      pd->pool->verbose = verbose;

      // Solve !
      solve( solv, &(pd->trials) );
      // clean up

      solver_free(solv);
      queue_free( &(pd->trials) );
    }
    break;
    default:
      break;
    }
  pd->state = pd->sbtab[pd->state];
  pd->docontent = 0;
  // printf("back from known %d %d %d\n", pd->state, pd->depth, pd->statedepth);
}


/*
 * XML callback
 * character data
 *
 */

static void XMLCALL
characterData( void *userData, const XML_Char *s, int len )
{
  Parsedata *pd = (Parsedata *)userData;
  int l;
  char *c;

  // check if current nodes content is interesting
  if (!pd->docontent)
    return;

  // adapt content buffer
  l = pd->lcontent + len + 1;
  if (l > pd->acontent)
    {
      pd->content = (char *)realloc( pd->content, l + 256 );
      pd->acontent = l + 256;
    }
  // append new content to buffer
  c = pd->content + pd->lcontent;
  pd->lcontent += len;
  while (len-- > 0)
    *c++ = *s++;
  *c = 0;
}

/*-------------------------------------------------------------------*/

static void
usage( void )
{
  fprintf( stderr, "Usage: deptestomatic [-v] <test-xml>\n" );
  exit( 1 );
}

#define BUFF_SIZE 8192

/*
 * read 'helix' type xml test description
 *
 */

int
main( int argc, char **argv )
{
  Parsedata pd;
  int i;
  struct stateswitch *sw;

  // prepare parsedata
  memset( &pd, 0, sizeof( pd ) );
  for (i = 0, sw = stateswitches; sw->from != NUMSTATES; i++, sw++)
    {
      if (!pd.swtab[sw->from])
        pd.swtab[sw->from] = sw;
      pd.sbtab[sw->to] = sw->from;
    }

  pd.pool = pool_create();
  pd.pool->nscallback = nscallback;
  pd.pool->nscallbackdata = &pd;
  queue_init( &pd.trials );

  pd.nchannels = 0;
  pd.channels = NULL;

  pd.system = NULL;

  pd.content = (char *)malloc( 256 );
  pd.acontent = 256;
  pd.lcontent = 0;

  /*
   * policies
   */

  pd.allowuninstall = 0;

  /*
   * set up XML parser
   */

  XML_Parser parser = XML_ParserCreate( NULL );
  XML_SetUserData( parser, &pd);       /* make parserdata available to XML callbacks */
  XML_SetElementHandler( parser, startElement, endElement );
  XML_SetCharacterDataHandler( parser, characterData );

  int argp = 1;
  if (argp < argc && !strcmp( argv[argp], "--redcarpet" ))
    {
      redcarpet = 1;
      pd.allowuninstall = 1;
      ++argp;
    }

  if (argp < argc && !strcmp( argv[argp], "-v" ))
    {
      verbose = 1;
      ++argp;
    }

  if (argp >= argc || !strcmp( argv[argp], "-h" ))
    {
      usage();
    }

  strncpy(pd.directory, argv[argp], PATH_MAX);
  memmove(pd.directory, dirname(pd.directory), strlen(pd.directory));
  if (pd.directory[strlen(pd.directory)-1] != '/')
	strncat(pd.directory, "/", PATH_MAX);
  // if it's . then use empty
  if (!strcmp(pd.directory, "./"))
     pd.directory[0] = 0;

  FILE *fp = fopen( argv[argp], "r" );
  if (!fp) {
    perror( argv[argp] );
    return 1;
  }

  Current = argv[argp];

  // read/parse XML file
  for (;;)
    {
      char buf[BUFF_SIZE];
      int l;

      l = fread( buf, 1, sizeof(buf), fp );
      if (XML_Parse( parser, buf, l, l == 0 ) == XML_STATUS_ERROR)
	{
	  err( "%s at line %u\n", XML_ErrorString(XML_GetErrorCode( parser )), (unsigned int)XML_GetCurrentLineNumber( parser ) );
	  exit(1);
	}
      if (l == 0)
	break;
    }
  XML_ParserFree( parser );
  fclose( fp );

  for ( i = 0; i < pd.nchannels; ++i )
    {
      free( pd.channels[i].name );
      pool_freerepo( pd.pool, pd.channels[i].repo );
    }

  for ( i = 0; i < pd.nmodaliases; ++i )
    free( pd.modaliases[i] );
  free( pd.modaliases );

  if ( pd.hardwareinfo)
    free( pd.hardwareinfo );

  pool_free( pd.pool );
  free( pd.channels );
  free( pd.content );

  return 0;
}
