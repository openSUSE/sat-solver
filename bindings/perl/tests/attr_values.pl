#!/usr/bin/perl

#
# attr_values.pl
#
# Test iterating over values of a specific attribute
#
#

use lib '../../../build/bindings/perl';

use satsolver;


# Create Pool and Repository 
my $pool = new satsolver::Pool;
$pool->set_arch( "i686" );
my $repo = $pool->create_repo('test') || die;

# Add Solvable to Repository
$repo->add_solv ("../../testdata/os11-beta5-i386.solv");

$pool->prepare();

# Print how much we have
print "\"" . $repo->name() . "\" size: " . $repo->size() . "\n";

print "\nFinding values for attribute 'solvable:keywords' ...\n";

my $solvable = $repo->find("perl") || die;

# FIXME !
#
# satsolver::Dataiterator->value() is a variant, returning different
#  types (string, int, bool, array) depending on the attribute.
# This doesn't work correctly in Perl
#
my $di = new satsolver::Dataiterator($pool,$repo,undef,0,$solvable,"solvable:keywords");
while ($di->step() != 0) {
  print "di $di\n";
  my @v = $di->value();
  print "at-vau @v\n";
  foreach my $v1 (@v) {
    print "vau1 $v1\n";
    foreach my $v ($v1) {
      print "vau $v\n";
    }
  }    
}