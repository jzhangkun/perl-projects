package WMCOM::Logbench;
use Time::HiRes qw(gettimeofday tv_interval);
use Scalar::Util qw/weaken/; #add to fix circular reference

sub new {
    my $self = shift;
    my %arg = @_;
    # Instantiate the object;
    my $type = ref($self) || $self;
    my $logbench = bless({}, $type);
    if (exists($arg{log})) {
        $logbench->{log_ref} = $arg{log};
        weaken( $logbench->{log_ref} );  # make it a weak reference, avoid memory leakage
    }
    $logbench->{start_time} = {};
    return $logbench;
}

sub start_bench {
    my ($self, $maincode) = @_;
    $self->{start_time}->{$maincode} = [gettimeofday];
}

sub end_bench {
    my ($self, $maincode,$subcode) = @_;
    if ( defined $self->{start_time}->{$maincode} ){
        my $e_time = tv_interval( $self->{start_time}->{$maincode} );
        delete $self->{start_time}->{$maincode};
        $self->write_bench($maincode, $subcode, $e_time);
        return int($e_time * 1000);
    }
    return undef;
}

sub write_bench {
    my ($self, $maincode, $subcode, $elapsedtime) = @_;
    $elapsedtime = int($elapsedtime * 1000);
    if ( $self->{log_ref} ) {
        my ($ss,$mi,$hh,$dd,$mm,$yy) = localtime;
        $mm += 1;
        $yy += 1900;
        my $msg = sprintf(' [%04d-%02d-%02d %02d:%02d:%02d] %s BENCH: { %s } -> millis = %d elapsed',$yy,$mm,$dd,$hh,$mi,$ss,$maincode,$subcode,$elapsedtime); 
        $self->{log_ref}->write($msg);
    }
}


1;
