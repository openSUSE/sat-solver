#!/usr/bin/perl

#
# repo.pl
#
# Test Repo functions
#
#

use lib '../../../build/bindings/perl';

use satsolver;

# Create Pool and Repository 
my $pool = new satsolver::Pool;
$pool->set_arch( $sysarch );
my $repo = $pool->create_repo('test') || die;

# Add solvables to Repository
$repo->add_solv ("../../testdata/timestamp.solv");

# Print how much we have
print "Pool size: " . $pool->size() . ", count " . $pool->count() . "\n";
print "Repo \"" . $repo->name() . "\" size " . $repo->size() . ", count " . $repo->count() . "\n";

my $timestamp = $repo->attr("repository:timestamp");

print "Timestamp: " . $timestamp . "\n";

print "Addedfileprovides: " . $repo->attr("repository:addedfileprovides") . "\n";
