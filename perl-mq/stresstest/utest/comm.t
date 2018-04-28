#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More tests => 2;

BEGIN { 
    my $runlevel = $ENV{WM_RUN_LEVEL} || "DEV";
    if ($runlevel eq 'DEV') {
        require Test::MockObject;
        my $test = Test::MockObject->new();
        for (qw{ MQSeries 
                 MQSeries::QueueManager
                 MQSeries::Queue
                 MQSeries::Message 
                 }) {
            $test->fake_module($_);
        }
    }
    use_ok("WMMQ::Comm");
}

my $conf = 1;
my $log  = 1;
my $mq = new_ok("WMMQ::Comm" => [ conf => $conf, log => $log]);

