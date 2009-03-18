#!/usr/bin/perl

#
# solvables.pl
#
# Test iterating over solvables of Pool or Repo
#
#

use lib '../../../build/bindings/perl';

use satsolver;

# Create Pool and Repository 
my $pool = new satsolver::Pool;
$pool->set_arch( $sysarch );
my $repo = $pool->create_repo('test') || die;

# Add solvables to Repository
$repo->add_solv ("../../testdata/os11-biarch.solv");

# Print how much we have
print "Pool size: " . $pool->size() . ", count " . $pool->count() . "\n";
print "Repo \"" . $repo->name() . "\" size " . $repo->size() . ", count " . $repo->count() . "\n";

my $poolcount = 0;
foreach my $solvable ($pool->solvables()) {
  next if not defined $solvable;
  $poolcount++;
}

foreach my $solvable ($pool->solvables()) {
  $solvable->pool() == $pool || die
}

my $repocount = 0;
foreach my $solvable ($repo->solvables()) {
  next if not defined $solvable;
  $repocount++;
}

print "Solvables in pool: " . $poolcount . ", in Repo " . $repocount . "\n";
