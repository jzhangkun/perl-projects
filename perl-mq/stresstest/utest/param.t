#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More tests => 2;

BEGIN { 
    use_ok("WMMQ::Param" => qw{ loadEnv loadConf });
    can_ok(__PACKAGE__,     qw{ loadEnv loadConf });
}

