#!/usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../../../build/bindings/perl";

use strict;
use satsolver;

my @packs = qw(vim postfix sendmail);

# Create Pool and Repository 
my $pool = new satsolver::Pool;
my $arch = qx (uname -m); chomp $arch;
$pool -> set_arch ($arch);
my $repo = $pool -> create_repo('repo');

# Add Solvable to Repository
$repo -> add_solv (
	"$Bin/../../testdata/demo.solv"
);

# Create Solver
my $solver = new satsolver::Solver ($pool);

# Create dependencies to provides table
$pool->prepare();

# Create Request
my $job = $pool->create_request();

# Add jobs
foreach my $p (@packs) {
	my $pat = $pool->find($p) || die "Failed to push job: $p";
#        if ($pat->name() != "sendmail") {
	    $job->install($pat);
#	}
}

# Solve the jobs
$solver->solve($job);

# Problems
my $pc = $solver->problems_count();
if ($pc) {
    print "Found $pc problems\n";
	my @problems = $solver->problems ($job);
	foreach my $p (@problems) {
	        my $ps = $p->string();
		print "Problem $ps\n";
	        my @solutions = $p->solutions();
	        foreach my $s (@solutions) {
		    my $ss = $s->string();
		    print "  Solution $ss\n";
		}
	}
}

my $t = $solver->transaction();
if ($t) {
    my $ts = $solver->transaction_string();
    print "Transaction $ts\n";
}
else {
    print "No transaction computed\n";
    }
exit 1;
# get install size
my $size = getInstallSizeKBytes($repo,$solver);
print "REQUIRED SIZE: $size kB\n";

# my $transaction = $solver->transaction();
# my $sizechange = $transaction->sizechange();
# print "SIZE CHANGE: $sizechange kB\n";


# Print packages to install
my @a = $solver->installs(1);
foreach my $solvable (@a) {
        my $arch = $solvable->attr_values("solvable:arch");
	my $size = $solvable->attr_values("solvable:installsize");
	my $ver  = $solvable->attr_values("solvable:evr");
        my $solv = $solvable->string();
	print "$solv -> $size Kbytes\n";
}


sub getInstallSizeKBytes {
	my $repo   = shift;
	my $solver = shift;
	my $sum    = 0;
	my @a = $solver->installs(1);
	foreach my $solvable (@a) {
		my $size = $solvable->attr_values("solvable:installsize");
		$sum += $size;
	}
	return $sum;
}
