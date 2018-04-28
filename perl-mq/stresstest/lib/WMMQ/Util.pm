package WMMQ::Util;
use Exporter;
use strict;
use warnings;
use Data::Dumper;
use MQSeries;
use MQSeries::QueueManager;
use MQSeries::Command;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw(QMsgCnt);

sub QMsgCnt {
    my ($qcmd, $qname) = @_;
    my $ra_qattr = $qcmd->InquireQueue(
            QName  => $qname,
            QAttrs => [
                        'CurrentQDepth',
                        'OpenInputCount',
                        'OpenOutputCount',
                      ],
    );
    return $ra_qattr->{CurrentQDepth};
}
 
1;
