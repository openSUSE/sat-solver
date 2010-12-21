#!/usr/bin/perl

#
# providers.pl
#
# Test iterating over provider of name or relation
#
#

use FindBin qw($Bin);
use lib "$Bin/../../../build/bindings/perl";

use satsolver;

# Open Solvable file
# open(F, "gzip -cd tmp/primary.gz |") || die;

# Create Pool and Repository 
my $pool = new satsolver::Pool;
$pool->set_arch( $sysarch );
my $repo = $pool->create_repo('test') || die;

# Add Solvable to Repository
$repo->add_solv ("$Bin/../../testdata/os11-biarch.solv");

# Create dependencies to provides table
$pool->prepare();

# Print how much we have
print "\"" . $repo->name() . "\" size: " . $repo->size() . "\n";

# Find a Solvable in the Repo
my $solvname = "aaa_base";
my $mysolvable = $repo->find($solvname);
die "could not find $solvname" if not defined $mysolvable;

# Create a Relation
my $rel = $pool->create_relation($mysolvable->name());

# Find Providers of Relation $rel
$solvname = $mysolvable->string();
my $rel_s = $rel->string();
print "\nFinding providers for relation $rel_s ...\n";
foreach my $solvable ($pool->providers($rel)) {
  print "--\n";
  next if not defined $solvable;

  my $name = $solvable->name();
  next if not defined $name;
  print "  solvable name: $name\n";

  if ($solvable == $mysolvable) {
    print "  found in repo $reponame\n";
    last;
  }
}

# Find Providers of Solvables identified by a name only
$solvname = "perl";
print "\nFinding providers for name $solvname\n";
foreach my $solvable ($pool->providers($solvname)) {
  print "--\n";
  next if not defined $solvable;

  my $name = $solvable->name();
  next if not defined $name;
  print "  solvable name: $name\n";
}
