package WMMQ::Comm;
use strict;
use warnings;
use Data::Dumper;
use MQSeries;
use MQSeries::QueueManager;
use MQSeries::Queue;
use MQSeries::Message;

sub new {
    my $instance = shift;
    my $class = ref($instance) || $instance; 
    my $self  = {};
    my %InParam = @_;
    if (exists $InParam{conf}) {
        $self->{conf} = $InParam{conf};
    } else {
        die "MQ config params are required!";
    }
    if (exists $InParam{log}) {
        $self->{log}  = $InParam{log};
    } else {
        die "Log handler are required!";
    }
    return bless $self, $class;
}

sub connectQM {
    my $self = shift;
    my $conf = $self->{conf};
    my $qmgr = MQSeries::QueueManager->new(
        QueueManager => "$conf->{queuemgr}",
        ClientConn   => { 'ChannelName'    => "$conf->{channel}",
                          'TransportType'  => "$conf->{transporttype}", # Default is TCP
                          'ConnectionName' => "$conf->{server}($conf->{port})",
                          'MaxMsgLength'   => "$conf->{maxlength}",
                        }                     # Refer spackle_prod.sh for values of these variables
    );
    $self->{qmgr} = $qmgr;
}

sub checkMQ {
    my $self = shift;
    my $conf = shift;
    $self = $self->new(conf => $conf, log => 1);
    $self->connectQM();
    return defined $self->{qmgr};
}

sub enqueueMailMessage {
    my $self = shift;
    my $operation = shift;
    my $msgqueue  = shift;
    my $message   = shift;
    my $enqueueMsgThreshold = shift || 1;
    my $logtag = "[enqueueMailMessage/$operation]";

    my $program_log = $self->{log};
    # Connect to Queue Manager
    $program_log->{log_bench}->start_bench("MQ") if $program_log;
    $self->connectQM();
    $program_log->{log_bench}->end_bench("MQ" => "ConnQM") if $program_log;

    # Open the queue
    $program_log->{log_bench}->start_bench("MQ") if $program_log;
    my $queue = MQSeries::Queue->new (
        QueueManager => $self->{qmgr},
        Queue => "$msgqueue",
        Mode => 'output'
    ) or $program_log->exit(1, "WM::ERR::$logtag Unable to open the queue: $msgqueue.");
    $program_log->{log_bench}->end_bench("MQ" => "OpenQ") if $program_log;
   
    for my $i (1..$enqueueMsgThreshold) {
        my $putmessage = MQSeries::Message->new(Data => $message);

        # Enqueue it
        $program_log->{log_bench}->start_bench("MQ");
        my $success = $queue->Put(Message => $putmessage);
        $program_log->{log_bench}->end_bench("MQ" =>  "Put");
        if ($success) {
            $program_log->write("$logtag Successfully enqueued the mail content");
        } else {
            $program_log->exit(1,"WM::ERR::$logtag Unable to put mail content on queue: $msgqueue: MQ ReasonCode =".$queue->Reason());
        }
    }

    # Close the queue
    $queue->Close();

} # End of enqueueMailMessage

sub dequeueMailMessage {
    my $self = shift;
    my $operation = shift;
    my $msgqueue  = shift;
    my $dequeueMsgThreshold   = shift || 1;
    my $logtag = "dequeueMailMessage";

    my $program_log = $self->{log};
    # Connect to Queue Manager
    $program_log->{log_bench}->start_bench("MQ");
    $self->connectQM;
    $program_log->{log_bench}->end_bench("MQ" => "ConnQM");

    # Open the queue
    $program_log->{log_bench}->start_bench("MQ");
    my $queue = MQSeries::Queue->new
      (
        QueueManager => $self->{qmgr},
        Queue => "$msgqueue",
        Mode => 'input'
      ) || $program_log->exit(1, "WM::ERR::[$logtag/$operation] Unable to open the queue: $msgqueue.");
    $program_log->{log_bench}->end_bench("MQ" => "OpenQ");

    my @messages = ();
    # Dequeue the messages
    for (my $i=1; $i<=$dequeueMsgThreshold; $i++) {
       my $getmessage = MQSeries::Message->new;
       
       $program_log->{log_bench}->start_bench("MQ");
       $queue->Get
       (
        Message => $getmessage,
        Sync => 1,
       ) || $program_log->write("[$logtag/$operation] Unable to dequeue message from the queue: $msgqueue");
       $program_log->{log_bench}->end_bench("MQ" => "Get");

       if ((my $message = $getmessage->Data())) {
           push(@messages, $message);
           $queue->QueueManager()->Commit()
           || $program_log->write("[emailTransport/$logtag/$operation] Unable to commit changes to queue: $msgqueue");
       } else {
           $queue->QueueManager()->Backout()
           || $program_log->write("[emailTransport/$logtag/$operation] Unable to backout changes to queue");
       }

    } # End of for loop

    # Close the queue
    $queue->Close();

    return \@messages;

} # End of dequeueMailMessage


1;
