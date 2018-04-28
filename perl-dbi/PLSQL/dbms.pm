#!/usr/local/bin/perl

################################################################################
# WMCOM::dbms.pm - Subroutines for executing PL/SQL API's.                     #
################################################################################

package dbms;

use strict;
use WMCOM::log;
use DBI;
use DBD::Oracle qw(:ora_types);

# Define version number and $AUTOLOAD string
use vars qw($VERSION $AUTOLOAD);
$VERSION = "1.0";

################################################################################
# DBMS Utility Subroutines:                                                    #
#                                                                              #
#   new($db,$dbuser,$dbpasswd,$log) - Create a database session using the      #
#     first three parameters and associate the log file if present.            #
#                                                                              #
#   warning($message) - Write SQL execute error message the defined log file   #
#     or to STDERR.                                                            #
#                                                                              #
#   failure($message) - Write SQL execute error message the defined log file   #
#     or to STDERR.  When finished, exit program.                              #
#                                                                              #
#   AUTOLOAD - If an undefined method is called, then de-reference the         #
#     database connection and call the method on that object.                  #
#                                                                              #
################################################################################

sub new {
    my $self = shift;
    my %arg = @_;

    # Instantiate the object;
    my $type = ref($self) || $self;
    my $dbh = bless({}, $type);

    # Add log reference to the object package
    if (exists($arg{log})) {
        $dbh->{'log_ref'} = $arg{log};
        $dbh->{debug} = $arg{log}->{'debug'} || 0;
    }

    # Define database parameters
    $dbh->{LOGREQUEST} = $arg{LOGREQUEST} if (exists($arg{LOGREQUEST})); # used in execute_procedure
    $dbh->{DEBUGREQUEST} = $arg{DEBUGREQUEST} if (exists($arg{DEBUGREQUEST})); # used in execute_procedure
    $dbh->{LOGERROR} = $arg{LOGERROR}; # used in execute_procedure
    $dbh->{db} = $arg{db} if (exists($arg{db}));
    $dbh->{dbuser} = $arg{dbuser} if (exists($arg{dbuser}));
    $dbh->{dbpasswd} = $arg{dbpasswd} if (exists($arg{dbpasswd}));
    # Open the database connection
    my $result = $dbh->_connect;
    # Write connection to log and return
    my $program_log = $dbh->{'log_ref'};
    if ($program_log) {
      $program_log->write("[WMCOM::dbms::new] Connected to $arg{dbuser}\@$arg{db}");
    }
        return $result unless $result; #did not connect to db, must return scaler with undef value
    return($dbh);
}

sub _connect {
    my $dbh = shift;

    my $dbma = DBI->connect("dbi:Oracle:$dbh->{db}", "$dbh->{dbuser}", "$dbh->{dbpasswd}",
        { PrintError => 0, AutoCommit => 0 });

    # Check database connection and add to the object package
    if (defined $dbma) {
        $dbh->{'dbma_ref'} = $dbma;
        $dbma->{'LongReadLen'}=1000000000; # limit characters read in to 1Gb
        $dbma->{'LongTruncOk'}=0;
    }
    else {
        $dbh->log_failure("Database connection to $dbh->{db} as $dbh->{dbuser} failed.");
        return undef;
    }
        return 1;
}

sub log_warning {
    my $dbh = shift;
    my $logtag=shift;
    my $message=shift;

    if (defined $dbh->{'log_ref'}) {
        my $program_log = $dbh->{'log_ref'};
        my $master_logtag=$program_log->get_errvars("logtag");
        my $master_subsystem=$program_log->get_errvars("subsystem");
        if ($master_subsystem eq $ENV{SUBSYSTEM_FILE_TRANSFER}){
           $program_log->set_errvars("enumber=4600");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_CREDIT_CARD}){
           $program_log->set_errvars("enumber=6600");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_INVENTORY}){
           $program_log->set_errvars("enumber=2600");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_ORDER_MANAGEMENT}){
           $program_log->set_errvars("enumber=8600");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_EMAIL_GENERATION}){
           $program_log->set_errvars("enumber=9400");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_ALARMS_TIMEOUTS}){
           $program_log->set_errvars("enumber=9600");
           }
        elsif ($master_subsystem eq $ENV{SUBSYSTEM_REPORTING}){
           $program_log->set_errvars("enumber=7400");
           }
         elsif ($master_subsystem eq $ENV{SUBSYSTEM_CATALOG}){
           $program_log->set_errvars("enumber=7600");
           }
         else{
           $program_log->set_errvars("enumber=1500");
           }
           $program_log->set_errvars("logtag=$logtag","message=$message Oracle Error Messages:\n$DBI::errstr");
           $program_log->format_err();
           $program_log->set_errvars("logtag=$master_logtag");
    }
    else {
        print STDERR ("$message\n");
        print STDERR ("Oracle Error Messages:\n$DBI::errstr\n");
    }
}
################################################################################
sub log_debug {
    my $dbh = shift;
    my $message = shift || "empty message";
    my $level = shift || 0;

    if ($level < $dbh->{debug}) {
                if (defined $dbh->{'log_ref'}) {
                        my $program_log = $dbh->{'log_ref'};
                        $program_log->write($message);
                }
                else {
                        print STDERR ("$message\n");
                }
        }
    return;
}
################################################################################
sub log_failure {
    my $dbh = shift;
    my $message = shift;
    $message='' unless defined($message);
    if (defined $dbh->{'log_ref'}) {
        my $program_log = $dbh->{'log_ref'};
           $program_log->set_errvars("enumber=1510","logtag=[WMCOM::dbms::new]","message=$message\nOracle Error Messages:\n".($DBI::errstr||''));
           $program_log->format_err();
           $dbh->disconnect if (defined $dbh->{'dbma_ref'});
    }
    else {
        print STDERR ("$message\n");
        print STDERR ("Oracle Error Messages:\n$DBI::errstr\n") if defined $DBI::errstr;
        $dbh->disconnect if (defined $dbh->{'dbma_ref'});
    #    exit(1);
    }
}
################################################################################
sub execute_procedure {
    my $dbh = shift;
    my (%inputhash)=@_;
    my $proc=$inputhash{PROC} || die "Undefined proc";
    my $param=$inputhash{PARAM} || [];

    # do we want to see request in log?
    my ($logrequestflag,$dflag);
    # lowest priority
    $dflag='',$logrequestflag=$dbh->{LOGREQUEST} if exists($dbh->{LOGREQUEST}); # object level
    $dflag='* ',$logrequestflag=$dbh->{DEBUGREQUEST} if exists($dbh->{DEBUGREQUEST}) && $dbh->{debug};
    # medium priority
    $dflag='',$logrequestflag=$inputhash{LOGREQUEST} if exists($inputhash{LOGREQUEST}); # request level
    $dflag='* ',$logrequestflag=$inputhash{DEBUGREQUEST} if exists($inputhash{DEBUGREQUEST}) && $dbh->{debug};
    # highest priority
    $dflag='* ',$logrequestflag=$ENV{DBMS_EXECUTE_PROCEDURE_DEBUG} if exists($ENV{DBMS_EXECUTE_PROCEDURE_DEBUG}); # application level

    # do we want to see error in log?
    my $logerrorflag;
    # lowest priority
    $logerrorflag=$dbh->{LOGERROR} if exists($dbh->{LOGERROR}); # object level
    # medium priority
    $logerrorflag=$inputhash{LOGERROR} if exists($inputhash{LOGERROR}); # request level
    # highest priority
    $logerrorflag=$ENV{DBMS_EXECUTE_PROCEDURE_LOGERROR} if exists($ENV{DBMS_EXECUTE_PROCEDURE_LOGERROR}); # application level

    my $logtag = $proc; #getlogtag();

    my $placeholdername=1;
    my $paramstr=join(", ", map { ':v'.$placeholdername++ } grep { !defined($_) || $_ ne '__CURSOR__'} @$param);

    my $sqlstatement=qq{
        BEGIN
            $proc($paramstr);
            :outPut := 'ORA-00000: $proc executed.';
            exception when others then
                :outPut := sqlerrm;
                rollback;
        END;
    };

    my ($csr, @debug_param_strs, $outPut, $return_status, $DBI_errstr);

    $csr = $dbh->prepare_cached($sqlstatement) || $dbh->log_failure("Bad SQL statement: $sqlstatement\n");

for my $try (0..1) {
    last unless $csr;
    my $has_cursor = 0;
    for ($placeholdername=1;@$param;$placeholdername++) {
        my $par=shift(@$param);
        if (ref($par)) {
            push(@debug_param_strs,"/*".( defined($$par)?("'".((length($$par)<=50)?$$par:(substr($$par,0,20)."...skipped...len=".length($$par)))."'"):'NULL' )."*/:inout$placeholdername");
            $csr->bind_param_inout(":v$placeholdername", $par, 1000000) ||
                $dbh->log_failure("Could not bind :v$placeholdername to $sqlstatement\n");
        } else {
            if ($par && $par eq '__CURSOR__') {
                $has_cursor = 1;
                push(@debug_param_strs,":cursor$placeholdername");
                my $ptr=shift(@$param);
                $$ptr=bless({DBH=>$dbh, PROC=>$proc, PLACEHOLDER=>":v$placeholdername"},'WMCOM::dbmscursor');
                $csr->bind_param_inout(":v$placeholdername", \${$$ptr}{CURSOR}, 0, {ora_type=>ORA_RSET}) ||
                    $dbh->log_failure("Could not bind :v$placeholdername to $sqlstatement\n");
            } else {
                push(@debug_param_strs,"/*in$placeholdername*/".( defined($par)?("'".((length($par)<=50)?$par:(substr($par,0,20)."...skipped...len=".length($par)))."'"):'NULL' ));
                $csr->bind_param(":v$placeholdername", $par) ||
                    $dbh->log_failure("Could not bind :v$placeholdername to $sqlstatement\n");
            }
        }
    }
    $csr->bind_param_inout(":outPut",\$outPut,32000) ||
        $dbh->log_failure("Could not Bind :outPut to $sqlstatement\n");

    if (not $has_cursor and $dbh->{'log_ref'}->{log_bench}){
        $dbh->{'log_ref'}->{log_bench}->start_bench("DB");
    }

    $return_status = ($csr->execute && defined($outPut) && ($outPut=~/^ORA-00000: /))? 1 : 0;

    if (not $has_cursor and $dbh->{'log_ref'}->{log_bench}){
        $dbh->{'log_ref'}->{log_bench}->end_bench("DB","call $proc()");
    }

    $DBI_errstr=$DBI::errstr || '';
    #$dbh->log_failure("Execute failed.\n"
    #    . "SQL statement: \"".($sqlstatement||'')."\"\n"
    #    . "sqlerrm: \"".($outPut||'')."\"\n"
    #    . join("\n",@debug_param_strs)) unless $return_status || $logerrorflag;

    $csr->finish;

    if ($outPut =~ /ORA-(?:06508|0406[12])/ && $try == 0) { # package was recompiled, reconnect
#        delete $dbh->{dbma_ref}{CachedKids}{$sqlstatement};
        $dbh->disconnect;
        $dbh->_connect;
        $csr=$dbh->prepare_cached($sqlstatement)
    } else {
        last;
    }
}

    (my $errlogstr=($outPut||'')."\n".($DBI_errstr||''))=~s/\n/; /g;
    $dbh->{'log_ref'}->write(($return_status?'':'ERR::')
                             ."dbms:".($return_status?"Succeed":"Failed($errlogstr)")
                             .":$dflag$dbh->{dbuser}\@$dbh->{db}:$proc(".join(",",@debug_param_strs).")")
        if $logrequestflag || ($return_status==0 && $logerrorflag);
    ${$inputhash{STR4LOG}}=($return_status?"Succeed":"Failed($errlogstr)")
                          .":$dflag$dbh->{dbuser}\@$dbh->{db}:$proc(".join(",",@debug_param_strs).")"
        if $inputhash{STR4LOG} && ref($inputhash{STR4LOG}) eq 'SCALAR';
    return ($return_status);
} # End of execute_procedure
################################################################################
AUTOLOAD {
    my $dbh = shift;
    my $dbma = $dbh->{'dbma_ref'};
    my $method = $AUTOLOAD;

    # This avoids an error trying to call DESTROY
    return if $method =~ m/::DESTROY$/;

    # Strip $AUTOLOAD variable to get explicit method call
    $method =~ s/.*://;

    # Call method on database object and return results
    #print STDERR "ERROR: Undefined dbconnection\n" unless $dbma;
    #print STDERR "ERROR: Undefined method \"$method\" is called\n" unless $dbma->can($method);
    return($dbma->$method(@_));
}
################################################################################
################################################################################
################################################################################
package WMCOM::dbmscursor;
use vars qw($AUTOLOAD);
################################################################################
AUTOLOAD {
    my $cursor = shift;

    # Strip $AUTOLOAD variable to get explicit method call
    (my $method = $AUTOLOAD) =~ s/.*://;

    # This avoids an error trying to call DESTROY
    return if $method eq 'DESTROY';

    # only benchmark first fetch
    return($cursor->{CURSOR}->$method(@_)) if exists($cursor->{ELAPSEDTIME});

    $cursor->{STARTTIME}=time;
    if ($cursor->{DBH}{'log_ref'}->{log_bench}){
        $cursor->{DBH}{'log_ref'}->{log_bench}->start_bench("DB");    
    }
    my @res=wantarray?($cursor->{CURSOR}->$method(@_))
                     :scalar($cursor->{CURSOR}->$method(@_));
    if ($cursor->{DBH}{'log_ref'}->{log_bench}){
        $cursor->{DBH}{'log_ref'}->{log_bench}->end_bench("DB","call $cursor->{PROC}()");    
    }
    $cursor->{ENDTIME}=time;
    $cursor->{ELAPSEDTIME}=$cursor->{ENDTIME}-$cursor->{STARTTIME};

    if ($cursor->{ELAPSEDTIME}) {
        my $msg="Elapsed time of $cursor->{PROC}($cursor->{PLACEHOLDER}) = $cursor->{ELAPSEDTIME}";
        if ($cursor->{DBH}{LOGREQUEST}) {
            $cursor->{DBH}{'log_ref'}->write("INF::$msg");
        } elsif ($cursor->{DBH}{DEBUGREQUEST}) {
            $cursor->{DBH}{'log_ref'}->write("INF::* $msg");
        }
    }

    return(@res[0..$#res]); # have to be like that for cases when fetchrow in scalar context
}
################################################################################
1;
