#!/usr/local/bin/perl
# This script is used for clearing the message count in MQ
# for the stress test
# NOTICE: ONLY ALLOWED ON Q[stresstest]
# Author: Jack Zhang - jzha154
# Date  : 2015-10-28

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use WMMQ::Param qw(loadEnv);
use WMMQ::Comm;
use WMMQ::Util  qw(QMsgCnt);

use MQSeries::Command;
use Readonly;
Readonly::Scalar my $targetOP => 'stresstest';

# Environment
my $param = loadEnv();

# Connect to Queue Manager
my $mq = WMMQ::Comm->new(conf => $param->{mq}, log => 1);
my $qmgr = $mq->connectQM()
   or die "WM::ERR::Unable to connect to queue manager:\nConf -  ".Dumper($param->{mq});

my $qcmd = MQSeries::Command->new(QueueManager => $qmgr)
   or die("WM::ERR::Unable to instantiate command object\n");

my @a_qnames = $qcmd->InquireQueueNames();

# Q name validation
my $targetQ = 'BEDROCK.DMZ.'.uc($targetOP).'.MAIL';
if (!grep { $_ eq uc($targetQ) } @a_qnames) {
    print "No such Q[$targetQ] in MQ server! existing ... \n";
    exit(0);
}

# before the clear
my $orgcnt = QMsgCnt($qcmd, $targetQ);

$qcmd->ClearQueue(
    QName => $targetQ,
);

# after the clear
my $curcnt = QMsgCnt($qcmd, $targetQ);

if ($curcnt != 0) {
    print <<"FAIL"
* Failed to clear the messages on Q[$targetQ]
Original Queue Message Count => $orgcnt
Current  Queue Message Count => $curcnt

FAIL
} else {
    print <<"PASS"
Cleared Message on Q[$targetQ]
Queue Message Count => $orgcnt
PASS
}

exit 0;
