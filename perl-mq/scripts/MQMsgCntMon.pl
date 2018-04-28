#!/usr/local/bin/perl
# This script is used for monitoring the message count in MQ
# Author: Jack Zhang

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use MQSeries;
use MQSeries::QueueManager;
use MQSeries::Command;

# Default Params
my $s_system = 'mail';
my $s_interval = 5;  # unit: second
my $s_sorted = 'by_cnt';

# Options
if ( !GetOptions( 
       "system=s"   => \$s_system,
       "interval=i" => \$s_interval,
       "sorted=s"   => \$s_sorted,
     )) 
{
    my $usage = <<"USAGE";

This script is used to get the message count in MQ queue
Usage: 
  perl $0 --system=[system name] --interval=[seconds] --sorted=[by type]
  --system, optional, default is [mail] system
  --interval, optional, default is [5]s
  --sorted, optional, default is sorted by message count

USAGE
    print $usage;
    exit(0);
}

# Environment
my $queuemgr       = $ENV{MQ_QUEUEMGR};
my $channelname    = $ENV{MQ_CHANNEL};
my $transporttype  = $ENV{MQ_TRANSPORT_TYPE};
my $server         = $ENV{MQ_SERVER};
my $port           = $ENV{MQ_SERVER_PORT};
my $maxmsglength   = $ENV{MQ_MAX_MSGLENGTH};

# Connect to Queue Manager
my $qmgr = MQSeries::QueueManager->new(
   QueueManager => "$queuemgr",
   ClientConn   => { 'ChannelName'    => "$channelname",
                     'TransportType'  => "$transporttype", # Default is TCP
                     'ConnectionName' => "$server($port)",
                     'MaxMsgLength'   => '$maxmsglength'
                    }               # Refer spackle_prod.sh for values of these variables
    ) or die "WM::ERR::Unable to connect to queue manager: $queuemgr";

my $qcmd = MQSeries::Command->new(QueueManager => $qmgr)
      or die("Unable to instantiate command object\n");

my @a_qnames = $qcmd->InquireQueueNames();

my @a_sys_qnames;
my $s_max_length = 0;
my $s_uc_system  = uc($s_system);
for my $qname ( @a_qnames ) {
    push @a_sys_qnames, $qname;
    $s_max_length = length($qname) if length($qname) > $s_max_length;
}
unless ( scalar @a_sys_qnames ) {
    print "No such system[$s_system] in MQ server! exiting ... \n";
    exit(0);
}


# Display the message count
while (1) {
    print "\n**** \@ " . scalar localtime() . ", Freshing after ${s_interval}s ****\n";
    my $rh_msgcnt = msg_count($qcmd,\@a_sys_qnames);
    my $totalcnt  = 0;
    for my $qname ( sort { $rh_msgcnt->{$b} <=> $rh_msgcnt->{$a}
                                      or $a cmp $b
                         } keys %{$rh_msgcnt} ) {
        printf("%-${s_max_length}s => %6i\n",$qname, $rh_msgcnt->{$qname});
        $totalcnt += $rh_msgcnt->{$qname};
    }
    # display total amount in the queue
    printf("%-${s_max_length}s => %6i\n","Current Total Amount", $totalcnt);
    sleep $s_interval;
}

sub msg_count {
    my ( $qcmd, $rh_q ) = @_;

    my %msg_cnt;
    my $ra_qattr;
    for my $qname ( @{$rh_q} ) {
        $ra_qattr = $qcmd->InquireQueue( 
            QName  => $qname,
            QAttrs => [ 
                        'CurrentQDepth',
                        'OpenInputCount',
                        'OpenOutputCount',
                      ],
        );
        $msg_cnt{$qname} = $ra_qattr->{CurrentQDepth};
    }

    return \%msg_cnt;
}
