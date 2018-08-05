#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ResponseMapper;

# old 
my %oldRequestParam = (
    a => 1,
    b => 2,
    c => 3,
);

my %oldResponseParam = (
    ra => 1,
    rb => 2,
    rc => 3,
);

# new
my %newRequestParam = (
    na => 1,
    nb => 2,
    nc => 3,
);

my %newResponseParam = (
    rna => 1,
    rnb => 2,
    rmc => 3,
);

my %requestParamMapper = (
    a => 'ra',
    b => 'rb',
    c => 'rc',
);
my %responseParamMapper = (
    ra => 'rna',
    rb => 'rnb',
    rc => 'rnc',
);

_println("\nResponse");

my %digits2String = ( 1 => 'ONE', 2 => 'TWO', 3 => 'THREE' );
my $responseMapper = ResponseMapper->new(kmapper => \%responseParamMapper);
$responseMapper->addVmapper('ra' => \%digits2String);
$responseMapper->addVmapper('rb' => \%digits2String);
$responseMapper->addVmapper('rc' => \%digits2String);

my $response = $responseMapper->mapFrom(\%oldResponseParam);

print "OLD".Dumper(\%oldResponseParam);
print "NEW".Dumper($response);


exit 0;

sub _println {
    print "@_\n";
}

