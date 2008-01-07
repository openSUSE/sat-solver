#!/usr/bin/perl

use lib '../../../build/bindings/perl';

use satsolverx;

#
# Test for 'Pool' class of sat-solver perl bindings
#
my $pool = new satsolverx::Pool || die;
$pool -> set_arch( 'i686' );

# $pool->count_repos == 0
# $pool->size == 1

$pool->prepare();

my $system = $pool->find( 'system:system' ) || die;
