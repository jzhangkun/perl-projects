package WMMQ::Param;
use strict;
use warnings;
use Data::Dumper;
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( loadEnv loadConf );
use XML::Simple;

# Consider to move these info to a configuration file?
my $debug_email       = $ENV{WM_EMAIL_NOTIFY};
my $queuemgr          = $ENV{WM_MQ_QUEUEMGR};
my $channelname       = $ENV{WM_MQ_CHANNEL};
my $transporttype     = $ENV{WM_MQ_TRANSPORT_TYPE};
my $server            = $ENV{WM_MQ_SERVER};
my $port              = $ENV{WM_MQ_SERVER_PORT};
my $maxmsglength      = $ENV{WM_MQ_MAX_MSGLENGTH};
my $enqueueMsgThreshold = $ENV{WM_ENQUEUE_MESSAGE_THRESHOLD} || 1;
my $dequeueMsgThreshold = $ENV{WM_DEQUEUE_MESSAGE_THRESHOLD} || 1;

my @OPERATIONS = qw(
    cancellation
    creditcard
    giftregistry
    miscoms
    miscomsff
    optical
    orderconfirm
    pharmacy
    photo
    shopcard
    shipconfirm
    sitetostore
    tires
    onehourphoto
    marketplace
    shoplist
    mp
    mpomsff
    stresstest
);

sub loadEnv {
    # Load environment variables
    my $homedir = $ENV{WM_HOME};
    $homedir =~ s{(\w)(\s|/)*$}{$1/};

    my $conf = {
        user     => $ENV{USER},
        hostname => $ENV{HOSTNAME},
        homedir  => $homedir,
        debug_email => $ENV{WM_EMAIL_NOTIFY},
        run_level   => $ENV{WM_RUN_LEVEL},
        mq => {
            "queuemgr"  =>  $ENV{WM_MQ_QUEUEMGR},
            "channel"   =>  $ENV{WM_MQ_CHANNEL},
            "transporttype" =>  $ENV{WM_MQ_TRANSPORT_TYPE},
            "server"    =>  $ENV{WM_MQ_SERVER},
            "port"      =>  $ENV{WM_MQ_SERVER_PORT},
            "maxlength" =>  $ENV{WM_MQ_MAX_MSGLENGTH}
        },
        enqueueMsgThreshold => $ENV{WM_ENQUEUE_MESSAGE_THRESHOLD} || 1,
        dequeueMsgThreshold => $ENV{WM_DEQUEUE_MESSAGE_THRESHOLD} || 1,
        operations => \@OPERATIONS,
    };

    return $conf;
}

sub loadConf {
    my $conf_file = shift;
    my $xml = eval{ XMLin($conf_file, ForceArray => ['operation']) };
    die "not valied config file: $conf_file" if $@;
    
    return $xml;
}

1;
