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
# use x86_64, as this will consider both x86_64 and i?86 packages
$pool->set_arch( 'x86_64' );
my $repo1 = $pool->create_repo('test_x86_64') || die;

# Add Solvable to Repository
$repo1->add_solv ("$Bin/../../testdata/os11-beta5-x86_64.solv");

# Create another Repository 
my $repo2 = $pool->create_repo('test_biarch') || die;

# Add Solvable to Repository
$repo2->add_solv ("$Bin/../../testdata/os11-biarch.solv");

# Create dependencies to provides table
$pool->prepare();

# Print how much we have
print "\"" . $repo1->name() . "\" size: " . $repo1->size() . "\n";
print "\"" . $repo2->name() . "\" size: " . $repo2->size() . "\n";

# Find a Solvable in the x86_64 Repo
my $solvname = "aaa_base";
my $solvable1 = $repo1->find($solvname);
die if not defined $solvable1;

print "\n" . $repo1->name() . ": found: " . $solvable1->string() . "\n";

# Find Providers of this Solvable in the biarch Repo
print "\nFinding providers in the biarch repo for $solvname\n";
foreach my $solvable2 ($pool->providers($solvname)) {
  print "--\n";
  next if not defined $solvable2;

  if ($solvable1->identical($solvable2)) {
    printf("identical: %s and %s\n",
	    $solvable1->string(),
	    $solvable2->string());
  } else {
    printf("different: %s and %s\n",
	    $solvable1->string(),
	    $solvable2->string());
  }
}
