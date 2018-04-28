package CEProcUtil;
use strict;
use warnings;
use Data::Dumper;
use Shell qw(ps);
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( pspid );

# find the pid status
# PPID PID CMD
sub pspid {
    my @pids  = grep {/^\d+$/} @_;
    my @lines = ps("-o ppid -o pid -o args -p ".join(q{,} => @pids));
    shift @lines; # title
    my %proc;
    for (@lines) {
        s/^\s*//;
        s/\s*$//;
        my ($ppid, $pid, $cmd) = split(/\s+/,$_,3);
        $proc{$pid} = {
            ppid => $ppid,
            cmd  => $cmd,
        };
    }
    return \%proc;
}

sub lspid {
    my @pids  = grep {/^\d+$/} @_;
    print ps("-o ppid -o pid -o args -p ".join(q{,} => @pids));
}


1;
