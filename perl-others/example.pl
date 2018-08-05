#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

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

my $requestTransformer = gen_key_transformer(\%requestParamMapper);
_println("\nrequest");
while (my($k,$v) = each %oldRequestParam) {
    _println("old", $k, $v);
    _println("new", $requestTransformer->($k), $v);
}

_println("\nresponse");
my ($responseTransformer, $responseRegister) = gen_kv_transformer(\%responseParamMapper);
$responseRegister->('ra' => { 1 => 'ONE', 2 => 'TWO', 3 => 'THREE' });
$responseRegister->('rb' => gen_transformer({ 1 => 'ONE', 2 => 'TWO', 3 => 'THREE' }));

while (my ($k,$v) = each %oldResponseParam) {
    _println("old", $k, $v);
    _println("new", $responseTransformer->($k, $v));
}

exit 0;

sub _println {
    print "@_\n";
}

sub gen_transformer {
    my ($mapper) = @_;

    my $exists = sub {
        my ($key) = @_;
        return 1 if exists $mapper->{$key};
    };

    my $transformer = sub {
        my ($key) = @_;
        return $mapper->{$key} if exists $mapper->{$key};
    };

    return $transformer;
}

sub register_transformer {
    my ($kMapper) = @_;
    my $vMapper = {};

    my $register = sub {
        my ($k, $mapper) = @_;
        $vMapper->{$k} = $mapper;
    };
    
    my $transformer = sub {
        my ($k, $v) = @_;
        my ($nk, $nv) = ($k, $v);
        if (exists $kMapper->{$k}) {
            $nk = $kMapper->{$k};
            if (exists $vMapper->{$k}) {
                my $mapper = $vMapper->{$k};
                $nv = $mapper->{$v} if exists $mapper->{$v};
            }
        }
        return ($nk, $nv);
    };

    return ($transformer, $register);
}


sub gen_key_transformer {
    my ($mapper) = @_;

    my $transformer = sub {
        my ($key) = @_;
        return $mapper->{$key} if exists $mapper->{$key};
    };

    return $transformer;
}

sub gen_kv_transformer {
    my ($kMapper) = @_;
    my $vMapper = {};

    my $register = sub {
        my ($k, $mapper) = @_;
        $vMapper->{$k} = $mapper;
    };
    
    my $transformer = sub {
        my ($k, $v) = @_;
        my ($nk, $nv) = ($k, $v);
        if (exists $kMapper->{$k}) {
            $nk = $kMapper->{$k};
            if (exists $vMapper->{$k}) {
                my $mapper = $vMapper->{$k};
                $nv = $mapper->{$v} if exists $mapper->{$v};
            }
        }
        return ($nk, $nv);
    };

    return ($transformer, $register);
}

