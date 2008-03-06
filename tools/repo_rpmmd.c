/*
 * Copyright (c) 2007, Novell Inc.
 *
 * This program is licensed under the BSD license, read LICENSE.BSD
 * for further information
 */

#include <sys/types.h>
#include <limits.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <expat.h>

#include "pool.h"
#include "repo.h"
#include "tools_util.h"
#include "repo_rpmmd.h"


enum state {
  STATE_START,
  STATE_METADATA,
  STATE_SOLVABLE,
  STATE_PRODUCT,
  STATE_PATTERN,
  STATE_PATCH,
  STATE_NAME,
  STATE_ARCH,
  STATE_VERSION,

  // package rpm-md
  STATE_LOCATION,
  STATE_CHECKSUM,
  STATE_RPM_GROUP,
  STATE_RPM_LICENSE,

  /* resobject attributes */
  STATE_SUMMARY,
  STATE_DESCRIPTION,
  STATE_INSNOTIFY,
  STATE_DELNOTIFY,
  STATE_VENDOR,
  STATE_SIZE,
  STATE_TIME,
  STATE_DOWNLOADSIZE,
  STATE_INSTALLTIME,
  STATE_INSTALLONLY,
  
  /* patch */
  STATE_ID,
  STATE_TIMESTAMP,
  STATE_AFFECTSPKG,
  STATE_REBOOTNEEDED,

   // xml store pattern attributes
  STATE_CATEGORY, /* pattern and patches */
  STATE_SCRIPT,
  STATE_ICON,
  STATE_USERVISIBLE,
  STATE_DEFAULT,
  STATE_INSTALL_TIME,

  /* product */
  STATE_SHORTNAME,
  STATE_DISTNAME,
  STATE_DISTEDITION,
  STATE_SOURCE,
  STATE_RELNOTESURL,

  STATE_FORMAT,
  
  /* rpm-md dependencies inside the
     format tag */
  STATE_PROVIDES,
  STATE_REQUIRES,
  STATE_OBSOLETES,
  STATE_CONFLICTS,
  STATE_RECOMMENDS,
  STATE_SUPPLEMENTS,
  STATE_SUGGESTS,
  STATE_ENHANCES,
  STATE_FRESHENS,
  STATE_SOURCERPM,
  STATE_HEADERRANGE,

  STATE_CAPS_FORMAT,
  STATE_CAPS_VENDOR,
  STATE_CAPS_PROVIDES,
  STATE_CAPS_REQUIRES,
  STATE_CAPS_OBSOLETES,
  STATE_CAPS_CONFLICTS,
  STATE_CAPS_RECOMMENDS,
  STATE_CAPS_SUPPLEMENTS,
  STATE_CAPS_SUGGESTS,
  STATE_CAPS_ENHANCES,
  STATE_CAPS_FRESHENS,

  STATE_PROVIDESENTRY,
  STATE_REQUIRESENTRY,
  STATE_OBSOLETESENTRY,
  STATE_CONFLICTSENTRY,
  STATE_RECOMMENDSENTRY,
  STATE_SUPPLEMENTSENTRY,
  STATE_SUGGESTSENTRY,
  STATE_ENHANCESENTRY,
  STATE_FRESHENSENTRY,

  STATE_CAP_FRESHENS,
  STATE_CAP_PROVIDES,
  STATE_CAP_REQUIRES,
  STATE_CAP_OBSOLETES,
  STATE_CAP_CONFLICTS,
  STATE_CAP_SUGGESTS,
  STATE_CAP_RECOMMENDS,
  STATE_CAP_SUPPLEMENTS,
  STATE_CAP_ENHANCES,

  STATE_FILE,

  // general
  NUMSTATES
};

struct stateswitch {
  enum state from;
  char *ename;
  enum state to;
  int docontent;
};

static struct stateswitch stateswitches[] = {

  { STATE_START,       "product",         STATE_SOLVABLE, 0 },
  { STATE_START,       "pattern",         STATE_SOLVABLE, 0 },
  { STATE_START,       "patch",           STATE_SOLVABLE, 0 },

  { STATE_START,       "metadata",        STATE_METADATA, 0 },
  { STATE_METADATA,    "package",         STATE_SOLVABLE, 0 },
  
  { STATE_SOLVABLE,    "name",            STATE_NAME, 1 },
  { STATE_SOLVABLE,    "arch",            STATE_ARCH, 1 },
  { STATE_SOLVABLE,    "version",         STATE_VERSION, 0 },

  // package attributes rpm-md
  { STATE_SOLVABLE,    "location",        STATE_LOCATION, 0 },
  { STATE_SOLVABLE,    "checksum",        STATE_CHECKSUM, 1 },
  
  /* resobject attributes */

  { STATE_SOLVABLE,    "summary",         STATE_SUMMARY, 1 },
  { STATE_SOLVABLE,    "description",     STATE_DESCRIPTION, 1 },
  //{ STATE_SOLVABLE,    "???",         STATE_INSNOTIFY, 1 },
  //{ STATE_SOLVABLE,    "??",     STATE_DELNOTIFY, 1 },
  { STATE_SOLVABLE,    "vendor",          STATE_VENDOR, 1 },
  { STATE_SOLVABLE,    "size",            STATE_SIZE, 0 },
  { STATE_SOLVABLE,    "archive-size",    STATE_DOWNLOADSIZE, 1 },
  { STATE_SOLVABLE,    "install-time",    STATE_INSTALLTIME, 1 },
  { STATE_SOLVABLE,    "install-only",    STATE_INSTALLONLY, 1 },
  { STATE_SOLVABLE,    "time",            STATE_TIME, 0 },

  // xml store pattern attributes
  { STATE_SOLVABLE,    "script",          STATE_SCRIPT, 1 },
  { STATE_SOLVABLE,    "icon",            STATE_ICON, 1 },
  { STATE_SOLVABLE,    "uservisible",     STATE_USERVISIBLE, 1 },
  { STATE_SOLVABLE,    "category",        STATE_CATEGORY, 1 },
  { STATE_SOLVABLE,    "default",         STATE_DEFAULT, 1 },
  { STATE_SOLVABLE,    "install-time",    STATE_INSTALL_TIME, 1 },

  { STATE_SOLVABLE,    "format",          STATE_FORMAT, 0 },

  /* those are used in libzypp xml store */
  { STATE_SOLVABLE,    "obsoletes",       STATE_CAPS_OBSOLETES , 0 },
  { STATE_SOLVABLE,    "conflicts",       STATE_CAPS_CONFLICTS , 0 },
  { STATE_SOLVABLE,    "recommends",      STATE_CAPS_RECOMMENDS , 0 },
  { STATE_SOLVABLE,    "supplements",     STATE_CAPS_SUPPLEMENTS, 0 },
  { STATE_SOLVABLE,    "suggests",        STATE_CAPS_SUGGESTS, 0 },
  { STATE_SOLVABLE,    "enhances",        STATE_CAPS_ENHANCES, 0 },
  { STATE_SOLVABLE,    "freshens",        STATE_CAPS_FRESHENS, 0 },
  { STATE_SOLVABLE,    "provides",        STATE_CAPS_PROVIDES, 0 },
  { STATE_SOLVABLE,    "requires",        STATE_CAPS_REQUIRES, 0 },

  { STATE_CAPS_PROVIDES,    "capability",      STATE_CAP_PROVIDES, 1 },
  { STATE_CAPS_REQUIRES,    "capability",      STATE_CAP_REQUIRES, 1 },
  { STATE_CAPS_OBSOLETES,   "capability",      STATE_CAP_OBSOLETES, 1 },
  { STATE_CAPS_CONFLICTS,   "capability",      STATE_CAP_CONFLICTS, 1 },
  { STATE_CAPS_RECOMMENDS,  "capability",      STATE_CAP_RECOMMENDS, 1 },
  { STATE_CAPS_SUPPLEMENTS, "capability",      STATE_CAP_SUPPLEMENTS, 1 },
  { STATE_CAPS_SUGGESTS,    "capability",      STATE_CAP_SUGGESTS, 1 },
  { STATE_CAPS_ENHANCES,    "capability",      STATE_CAP_ENHANCES, 1 },
  { STATE_CAPS_FRESHENS,    "capability",      STATE_CAP_FRESHENS, 1 },
  
  { STATE_FORMAT,      "rpm:vendor",      STATE_VENDOR, 1 },
  { STATE_FORMAT,      "rpm:group",       STATE_RPM_GROUP, 1 },
  { STATE_FORMAT,      "rpm:license",     STATE_RPM_LICENSE, 1 },

  /* rpm-md dependencies */ 
  { STATE_FORMAT,      "rpm:provides",    STATE_PROVIDES, 0 },
  { STATE_FORMAT,      "rpm:requires",    STATE_REQUIRES, 0 },
  { STATE_FORMAT,      "rpm:obsoletes",   STATE_OBSOLETES , 0 },
  { STATE_FORMAT,      "rpm:conflicts",   STATE_CONFLICTS , 0 },
  { STATE_FORMAT,      "rpm:recommends",  STATE_RECOMMENDS , 0 },
  { STATE_FORMAT,      "rpm:supplements", STATE_SUPPLEMENTS, 0 },
  { STATE_FORMAT,      "rpm:suggests",    STATE_SUGGESTS, 0 },
  { STATE_FORMAT,      "rpm:enhances",    STATE_ENHANCES, 0 },
  { STATE_FORMAT,      "rpm:freshens",    STATE_FRESHENS, 0 },
  { STATE_FORMAT,      "rpm:sourcerpm",   STATE_SOURCERPM, 1 },
  { STATE_FORMAT,      "rpm:header-range", STATE_HEADERRANGE, 0 },
  { STATE_FORMAT,      "file",            STATE_FILE, 1 },
  { STATE_PROVIDES,    "rpm:entry",       STATE_PROVIDESENTRY, 0 },
  { STATE_REQUIRES,    "rpm:entry",       STATE_REQUIRESENTRY, 0 },
  { STATE_OBSOLETES,   "rpm:entry",       STATE_OBSOLETESENTRY, 0 },
  { STATE_CONFLICTS,   "rpm:entry",       STATE_CONFLICTSENTRY, 0 },
  { STATE_RECOMMENDS,  "rpm:entry",       STATE_RECOMMENDSENTRY, 0 },
  { STATE_SUPPLEMENTS, "rpm:entry",       STATE_SUPPLEMENTSENTRY, 0 },
  { STATE_SUGGESTS,    "rpm:entry",       STATE_SUGGESTSENTRY, 0 },
  { STATE_ENHANCES,    "rpm:entry",       STATE_ENHANCESENTRY, 0 },
  { STATE_FRESHENS,    "rpm:entry",       STATE_FRESHENSENTRY, 0 },
  { NUMSTATES}
};

struct parsedata {
  struct parsedata_common common;
  char *kind;
  int depth;
  enum state state;
  int statedepth;
  char *content;
  int lcontent;
  int acontent;
  int docontent;
  Solvable *solvable;
  struct stateswitch *swtab[NUMSTATES];
  enum state sbtab[NUMSTATES];
  const char *lang;
  const char *capkind;
  // used to store tmp attributes
  // while the tag ends
  const char *tmpattr;
  Repodata *data;
};

static char *flagtabnum[] = {
  ">",
  "=",
  ">=",
  "<",
  "!=",
  "<=",
};

/**
 * adds plain dependencies, that is strings like "foo > 2.0"
 * which are used in libzypp xml store, not in rpm-md.
 */
static unsigned int
adddepplain(Pool *pool, struct parsedata_common *pd, unsigned int olddeps, char *line, Id marker, const char *kind)
{
  int i, flags;
  Id id, evrid;
  char *sp[4];

  i = split(line, sp, 4);
  if (i != 1 && i != 3)
    {
      fprintf(stderr, "Bad dependency line: %s\n", line);
      exit(1);
    }
  if (kind)
    id = str2id(pool, join2(kind, ":", sp[0]), 1);
  else
    id = str2id(pool, sp[0], 1);
  if (i == 3)
    {
      evrid = makeevr(pool, sp[2]);
      for (flags = 0; flags < 6; flags++)
        if (!strcmp(sp[1], flagtabnum[flags]))
          break;
      if (flags == 6)
        {
          if ( !strcmp(sp[1], "=="))
           {
            flags = 1;
           }
          else
           {
            fprintf(stderr, "Unknown relation '%s'\n", sp[1]);
            exit(1);
           }
        }
      id = rel2id(pool, id, evrid, flags + 1, 1);
    }
  return repo_addid_dep(pd->repo, olddeps, id, marker);
}

static Id
makeevr_atts(Pool *pool, struct parsedata *pd, const char **atts)
{
  const char *e, *v, *r, *v2;
  char *c;
  int l;

  e = v = r = 0;
  for (; *atts; atts += 2)
    {
      if (!strcmp(*atts, "epoch"))
	e = atts[1];
      else if (!strcmp(*atts, "ver"))
	v = atts[1];
      else if (!strcmp(*atts, "rel"))
	r = atts[1];
    }
  if (e && !strcmp(e, "0"))
    e = 0;
  if (v && !e)
    {
      for (v2 = v; *v2 >= '0' && *v2 <= '9'; v2++)
        ;
      if (v2 > v && *v2 == ':')
	e = "0";
    }
  l = 1;
  if (e)
    l += strlen(e) + 1;
  if (v)
    l += strlen(v);
  if (r)
    l += strlen(r) + 1;
  if (l > pd->acontent)
    {
      pd->content = sat_realloc(pd->content, l + 256);
      pd->acontent = l + 256;
    }
  c = pd->content;
  if (e)
    {
      strcpy(c, e);
      c += strlen(c);
      *c++ = ':';
    }
  if (v)
    {
      strcpy(c, v);
      c += strlen(c);
    }
  if (r)
    {
      *c++ = '-';
      strcpy(c, r);
      c += strlen(c);
    }
  *c = 0;
  if (!*pd->content)
    return 0;
#if 0
  fprintf(stderr, "evr: %s\n", pd->content);
#endif
  return str2id(pool, pd->content, 1);
}

static inline const char *
find_attr(const char *txt, const char **atts)
{
  for (; *atts; atts += 2)
    {
      if (!strcmp(*atts, txt))
        return atts[1];
    }
  return 0;
}

static char *flagtab[] = {
  "GT",
  "EQ",
  "GE",
  "LT",
  "NE",
  "LE"
};

static unsigned int
adddep(Pool *pool, struct parsedata *pd, unsigned int olddeps, const char **atts, int isreq)
{
  Id id, name, marker;
  const char *n, *f, *k;
  const char **a;

  n = f = k = 0;
  marker = isreq ? -SOLVABLE_PREREQMARKER : 0;
  for (a = atts; *a; a += 2)
    {
      if (!strcmp(*a, "name"))
	n = a[1];
      else if (!strcmp(*a, "flags"))
	f = a[1];
      else if (!strcmp(*a, "kind"))
	k = a[1];
      else if (isreq && !strcmp(*a, "pre") && a[1][0] == '1')
	marker = SOLVABLE_PREREQMARKER;
    }
  if (!n)
    return olddeps;
  if (k && !strcmp(k, "package"))
    k = 0;
  if (k)
    {
      int l = strlen(k) + 1 + strlen(n) + 1;
      if (l > pd->acontent)
	{
	  pd->content = sat_realloc(pd->content, l + 256);
	  pd->acontent = l + 256;
	}
      sprintf(pd->content, "%s:%s", k, n); 
      name = str2id(pool, pd->content, 1); 
    }
  else
    name = str2id(pool, (char *)n, 1);
  if (f)
    {
      Id evr = makeevr_atts(pool, pd, atts);
      int flags;
      for (flags = 0; flags < 6; flags++)
	if (!strcmp(f, flagtab[flags]))
	  break;
      flags = flags < 6 ? flags + 1 : 0;
      id = rel2id(pool, name, evr, flags, 1);
    }
  else
    id = name;
#if 0
  fprintf(stderr, "new dep %s%s%s\n", id2str(pool, d), id2rel(pool, d), id2evr(pool, d));
#endif
  return repo_addid_dep(pd->common.repo, olddeps, id, marker);
}

static void
set_desciption_author(Repodata *data, Id entry, char *str)
{
  char *aut, *p;

  if (!str || !*str)
    return;
  for (aut = str; (aut = strchr(aut, '\n')) != 0; aut++)
    if (!strncmp(aut, "\nAuthors:\n--------\n", 19)) 
      break;
  if (aut)
    {
      /* oh my, found SUSE special author section */
      int l = aut - str; 
      str[l] = 0; 
      while (l > 0 && str[l - 1] == '\n')
	str[--l] = 0; 
      if (l)
	repodata_set_str(data, entry, SOLVABLE_DESCRIPTION, str);
      p = aut + 19;
      aut = str;        /* copy over */
      while (*p == ' ' || *p == '\n')
	p++;
      while (*p) 
	{
	  if (*p == '\n')
	    {
	      *aut++ = *p++;
	      while (*p == ' ') 
		p++;
	      continue;
	    }
	  *aut++ = *p++;
	}
      while (aut != str && aut[-1] == '\n')
	aut--;
      *aut = 0; 
      if (*str)
	repodata_set_str(data, entry, SOLVABLE_AUTHORS, str);
    }
  else if (*str)
    repodata_set_str(data, entry, SOLVABLE_DESCRIPTION, str);
}

static void
set_sourcerpm(Repodata *data, Solvable *s, Id entry, char *sourcerpm)
{
  const char *p, *sevr, *sarch, *name, *evr;
  Pool *pool;

    p = strrchr(sourcerpm, '.');
  if (!p || strcmp(p, ".rpm") != 0)
    return;
  p--;
  while (p > sourcerpm && *p != '.')
    p--;
  if (*p != '.' || p == sourcerpm)
    return;
  sarch = p-- + 1;
  while (p > sourcerpm && *p != '-')
    p--;
  if (*p != '-' || p == sourcerpm)
    return;
  p--;
  while (p > sourcerpm && *p != '-')
    p--;
  if (*p != '-' || p == sourcerpm)
    return;
  sevr = p + 1;
  pool = s->repo->pool;
  name = id2str(pool, s->name);
  evr = id2str(pool, s->evr);
  if (!strcmp(sarch, "src.rpm"))
    repodata_set_constantid(data, entry, SOLVABLE_SOURCEARCH, ARCH_SRC);
  else if (!strcmp(sarch, "nosrc.rpm"))
    repodata_set_constantid(data, entry, SOLVABLE_SOURCEARCH, ARCH_NOSRC);
  else
    repodata_set_constantid(data, entry, SOLVABLE_SOURCEARCH, strn2id(pool, sarch, strlen(sarch) - 4, 1));
  if (!strncmp(sevr, evr, sarch - sevr - 1) && evr[sarch - sevr - 1] == 0)
    repodata_set_void(data, entry, SOLVABLE_SOURCEEVR);
  else
    repodata_set_id(data, entry, SOLVABLE_SOURCEEVR, strn2id(pool, sevr, sarch - sevr - 1, 1));
  if (!strncmp(sourcerpm, name, sevr - sourcerpm - 1) && name[sevr - sourcerpm -
 1] == 0)
    repodata_set_void(data, entry, SOLVABLE_SOURCENAME);
  else
    repodata_set_id(data, entry, SOLVABLE_SOURCENAME, strn2id(pool, sourcerpm, sevr - sourcerpm - 1, 1));
}

static void XMLCALL
startElement(void *userData, const char *name, const char **atts)
{
  //fprintf(stderr,"+tag: %s\n", name);
  struct parsedata *pd = userData;
  Pool *pool = pd->common.pool;
  Solvable *s = pd->solvable;
  struct stateswitch *sw;
  const char *str;
  Id entry = s ? (s - pool->solvables) - pd->data->start : 0;

  if (pd->depth != pd->statedepth)
    {
      pd->depth++;
      return;
    }
  pd->depth++;
  for (sw = pd->swtab[pd->state]; sw->from == pd->state; sw++)
    if (!strcmp(sw->ename, name))
      break;
  if (sw->from != pd->state)
    {
#if 0
      fprintf(stderr, "into unknown: %s\n", name);
#endif
      return;
    }
  pd->state = sw->to;
  pd->docontent = sw->docontent;
  pd->statedepth = pd->depth;
  pd->lcontent = 0;
  *pd->content = 0;
  switch(pd->state)
    {
    case STATE_SOLVABLE:
      pd->kind = 0;
      if (name[2] == 't' && name[3] == 't')
        pd->kind = "pattern";
      else if (name[1] == 'r')
        pd->kind = "product";
      else if (name[2] == 't' && name[3] == 'c')
        pd->kind = "patch";
      
      pd->solvable = pool_id2solvable(pool, repo_add_solvable(pd->common.repo));
      repodata_extend(pd->data, pd->solvable - pool->solvables);
#if 0
      fprintf(stderr, "package #%d\n", pd->solvable - pool->solvables);
#endif
      break;
    case STATE_VERSION:
      s->evr = makeevr_atts(pool, pd, atts);
      break;
    case STATE_CAPS_PROVIDES:
    case STATE_PROVIDES:
      s->provides = 0;
      break;
    case STATE_PROVIDESENTRY:
      s->provides = adddep(pool, pd, s->provides, atts, 0);
      break;
    case STATE_CAPS_REQUIRES:
    case STATE_REQUIRES:
      s->requires = 0;
      break;
    case STATE_REQUIRESENTRY:
      s->requires = adddep(pool, pd, s->requires, atts, 1);
      break;
    case STATE_CAPS_OBSOLETES:
    case STATE_OBSOLETES:
      s->obsoletes = 0;
      break;
    case STATE_OBSOLETESENTRY:
      s->obsoletes = adddep(pool, pd, s->obsoletes, atts, 0);
      break;
    case STATE_CAPS_CONFLICTS:
    case STATE_CONFLICTS:
      s->conflicts = 0;
      break;
    case STATE_CONFLICTSENTRY:
      s->conflicts = adddep(pool, pd, s->conflicts, atts, 0);
      break;
    case STATE_CAPS_RECOMMENDS:
    case STATE_RECOMMENDS:
      s->recommends = 0;
      break;
    case STATE_RECOMMENDSENTRY:
      s->recommends = adddep(pool, pd, s->recommends, atts, 0);
      break;
    case STATE_CAPS_SUPPLEMENTS:
    case STATE_SUPPLEMENTS:
      s->supplements= 0;
      break;
    case STATE_SUPPLEMENTSENTRY:
      s->supplements = adddep(pool, pd, s->supplements, atts, 0);
      break;
    case STATE_CAPS_SUGGESTS:
    case STATE_SUGGESTS:
      s->suggests = 0;
      break;
    case STATE_SUGGESTSENTRY:
      s->suggests = adddep(pool, pd, s->suggests, atts, 0);
      break;
    case STATE_CAPS_ENHANCES:
    case STATE_ENHANCES:
      s->enhances = 0;
      break;
    case STATE_ENHANCESENTRY:
      s->enhances = adddep(pool, pd, s->enhances, atts, 0);
      break;
    case STATE_CAPS_FRESHENS:
    case STATE_FRESHENS:
      s->freshens = 0;
      break;
    case STATE_FRESHENSENTRY:
      s->freshens = adddep(pool, pd, s->freshens, atts, 0);
      break;
    case STATE_CAP_PROVIDES:
    case STATE_CAP_REQUIRES:
    case STATE_CAP_OBSOLETES:
    case STATE_CAP_CONFLICTS:
    case STATE_CAP_RECOMMENDS:
    case STATE_CAP_SUPPLEMENTS:
    case STATE_CAP_SUGGESTS:
    case STATE_CAP_ENHANCES:
    case STATE_CAP_FRESHENS:
      pd->capkind = find_attr("kind", atts);
      //fprintf(stderr,"capkind es: %s\n", pd->capkind);
      break;
    case STATE_SUMMARY:
    case STATE_DESCRIPTION:
      pd->lang = find_attr("lang", atts);
      break;
    case STATE_LOCATION:
      str = find_attr("href", atts);
      if (str)
	{
	  const char *str2 = strrchr(str, '/');
	  if (str2)
	    {
	      char *str3 = strdup(str);
	      str3[str2 - str] = 0;
	      repodata_set_poolstr(pd->data, entry, SOLVABLE_MEDIADIR, str3);
	      free(str3);
              repodata_set_str(pd->data, entry, SOLVABLE_MEDIAFILE, str2 + 1);
	    }
	  else
            repodata_set_str(pd->data, entry, SOLVABLE_MEDIAFILE, str);
	}
      break;
    case STATE_CHECKSUM:
      pd->tmpattr = find_attr("type", atts);
      break;
    case STATE_TIME:
      {
        unsigned int t;
        str = find_attr("build", atts);
        if (str && (t = atoi(str)) != 0)
          repodata_set_num(pd->data, entry, SOLVABLE_BUILDTIME, t);
	break;
      }
    case STATE_SIZE:
      {
        unsigned int k;
        str = find_attr("installed", atts);
	if (str && (k = atoi(str)) != 0)
	  repodata_set_num(pd->data, entry, SOLVABLE_INSTALLSIZE, (k + 1023) / 1024);
	/* XXX the "package" attribute gives the size of the rpm file,
	   i.e. the download size.  Except on packman, there it seems to be
	   something else entirely, it has a value near to the other two
	   values, as if the rpm is uncompressed.  */
        str = find_attr("package", atts);
	if (str && (k = atoi(str)) != 0)
	  repodata_set_num(pd->data, entry, SOLVABLE_DOWNLOADSIZE, (k + 1023) / 1024);
        break;
      }
    case STATE_HEADERRANGE:
      {
        unsigned int end;
        str = find_attr("end", atts);
	if (str && (end = atoi(str)) != 0)
	  repodata_set_num(pd->data, entry, SOLVABLE_HEADEREND, end);
      }
    default:
      break;
    }
}

static void XMLCALL
endElement(void *userData, const char *name)
{
  //fprintf(stderr,"-tag: %s\n", name);
  struct parsedata *pd = userData;
  Pool *pool = pd->common.pool;
  Solvable *s = pd->solvable;
  Repo *repo = pd->common.repo;
  Id entry = s ? (s - pool->solvables) - pd->data->start : 0;
  Id id;
  char *p;

  if (pd->depth != pd->statedepth)
    {
      pd->depth--;
      // printf("back from unknown %d %d %d\n", pd->state, pd->depth, pd->statedepth);
      return;
    }
  pd->depth--;
  pd->statedepth--;
  switch (pd->state)
    {
    case STATE_PATTERN:
    case STATE_PRODUCT:
    case STATE_SOLVABLE:
      if (!s->arch)
        s->arch = ARCH_NOARCH;
      if (s->arch != ARCH_SRC && s->arch != ARCH_NOSRC)
        s->provides = repo_addid_dep(repo, s->provides, rel2id(pool, s->name, s->evr, REL_EQ, 1), 0);
      s->supplements = repo_fix_legacy(repo, s->provides, s->supplements);
      pd->kind = 0;
      break;
    case STATE_NAME:
      if ( pd->kind )
          s->name = str2id(pool, join2( pd->kind, ":", pd->content), 1);
      else
          s->name = str2id(pool, pd->content, 1);
      break;
    case STATE_ARCH:
      s->arch = str2id(pool, pd->content, 1);
      break;
    case STATE_VENDOR:
      s->vendor = str2id(pool, pd->content, 1);
      break;
    case STATE_RPM_GROUP:
      repodata_set_poolstr(pd->data, entry, SOLVABLE_GROUP, pd->content);
      break;
    case STATE_RPM_LICENSE:
      repodata_set_poolstr(pd->data, entry, SOLVABLE_LICENSE, pd->content);
      break;
    case STATE_FILE:
#if 0
      id = str2id(pool, pd->content, 1);
      s->provides = repo_addid_dep(repo, s->provides, id, SOLVABLE_FILEMARKER);
#endif
      if ((p = strrchr(pd->content, '/')) != 0)
	{
	  *p++ = 0;
	  id = repodata_str2dir(pd->data, pd->content, 1);
	}
      else
	{
	  p = pd->content;
	  id = repodata_str2dir(pd->data, "/", 1);
	}
      repodata_add_dirstr(pd->data, entry, SOLVABLE_FILELIST, id, p);
      break;
    // xml store capabilities
    case STATE_CAP_PROVIDES:
      s->provides = adddepplain(pool, &pd->common, s->provides, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_REQUIRES:
      s->requires = adddepplain(pool, &pd->common, s->requires, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_OBSOLETES:
      s->obsoletes = adddepplain(pool, &pd->common, s->obsoletes, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_CONFLICTS:
      s->conflicts = adddepplain(pool, &pd->common, s->conflicts, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_RECOMMENDS:
      s->recommends = adddepplain(pool, &pd->common, s->recommends, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_SUPPLEMENTS:
      s->supplements = adddepplain(pool, &pd->common, s->supplements, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_SUGGESTS:
      s->suggests = adddepplain(pool, &pd->common, s->suggests, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_ENHANCES:
      s->enhances = adddepplain(pool, &pd->common, s->enhances, pd->content, 0, pd->capkind);
      break;
    case STATE_CAP_FRESHENS:
      s->freshens = adddepplain(pool, &pd->common, s->freshens, pd->content, 0, pd->capkind);
      break;
    case STATE_SUMMARY:
      pd->lang = 0;
      repodata_set_str(pd->data, entry, SOLVABLE_SUMMARY, pd->content);
      break;
    case STATE_DESCRIPTION:
      pd->lang = 0;
      set_desciption_author(pd->data, entry, pd->content);
      break;
    case STATE_SOURCERPM:
      set_sourcerpm(pd->data, s, entry, pd->content);
      break;
    default:
      break;
    }
  pd->state = pd->sbtab[pd->state];
  pd->docontent = 0;
  //fprintf(stderr, "back from known %d %d %d\n", pd->state, pd->depth, pd->statedepth);
}

static void XMLCALL
characterData(void *userData, const XML_Char *s, int len)
{
  struct parsedata *pd = userData;
  int l;
  char *c;

  if (!pd->docontent)
    return;
  l = pd->lcontent + len + 1;
  if (l > pd->acontent)
    {
      pd->content = sat_realloc(pd->content, l + 256);
      pd->acontent = l + 256;
    }
  c = pd->content + pd->lcontent;
  pd->lcontent += len;
  while (len-- > 0)
    *c++ = *s++;
  *c = 0;
}


#define BUFF_SIZE 8192

void
repo_add_rpmmd(Repo *repo, FILE *fp, int flags)
{
  Pool *pool = repo->pool;
  struct parsedata pd;
  char buf[BUFF_SIZE];
  int i, l;
  struct stateswitch *sw;

  memset(&pd, 0, sizeof(pd));
  for (i = 0, sw = stateswitches; sw->from != NUMSTATES; i++, sw++)
    {
      if (!pd.swtab[sw->from])
        pd.swtab[sw->from] = sw;
      pd.sbtab[sw->to] = sw->from;
    }
  pd.common.pool = pool;
  pd.common.repo = repo;

  pd.data = repo_add_repodata(repo, 0);

  pd.content = sat_malloc(256);
  pd.acontent = 256;
  pd.lcontent = 0;
  pd.common.tmp = 0;
  pd.common.tmpl = 0;
  pd.kind = 0;
  XML_Parser parser = XML_ParserCreate(NULL);
  XML_SetUserData(parser, &pd);
  XML_SetElementHandler(parser, startElement, endElement);
  XML_SetCharacterDataHandler(parser, characterData);
  for (;;)
    {
      l = fread(buf, 1, sizeof(buf), fp);
      if (XML_Parse(parser, buf, l, l == 0) == XML_STATUS_ERROR)
	{
	  fprintf(stderr, "repo_rpmmd: %s at line %u:%u\n", XML_ErrorString(XML_GetErrorCode(parser)), (unsigned int)XML_GetCurrentLineNumber(parser), (unsigned int)XML_GetCurrentColumnNumber(parser));
	  exit(1);
	}
      if (l == 0)
	break;
    }
  XML_ParserFree(parser);

  if (pd.data)
    repodata_internalize(pd.data);
  sat_free(pd.content);
}
