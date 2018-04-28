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
                 MQSeries::Command
                 }) {
            $test->fake_module($_);
        }
    }
    use_ok("WMMQ::Util" => qw(QMsgCnt));
    can_ok(__PACKAGE__,    qw(QMsgCnt));
}

