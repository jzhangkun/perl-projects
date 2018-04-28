# To mock WMCOM::dbms for ut
package mocked_dbms;
@ISA = qw( Exporter );
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
our @EXPORT = qw( IN OUT CSR CLB );
use Carp;
use Scalar::Util qw(blessed);
use DBI;
our $AUTOLOAD;

my %registeredProc;
# Data structure
# key => 'proc'
# val -> 'spec'      : store the spec for this procedure
#     -> 'testdata'  : store all the test data

sub new { 
    my $class = shift;
    return bless {}, $class;
}

sub serialize {
    my $self = shift;
    my $data = shift;
    my (@IN, @DATA);
    for(my $placeholder=0; @$data; $placeholder++) {
        my $dataobj  = shift @$data;
        my $datatype = $self->_check_data_type($dataobj);
        push @DATA, $dataobj;
        push @IN,   ["v$placeholder",$dataobj->val] if $datatype eq 'dataIN';
    }

    # serialize uniq id
    my $utid = join('_' => map(join(':',@$_), @IN), # serialize the input parameter
                           "INNUM".scalar(@IN),     # input paramter counts
                           "TTNUM".scalar(@DATA));  # total paramter counts
    return ($utid,\@DATA);
}

# Register the spec for the procedure
# $self->register_procedure(PROC=>$proc, SPEC=>[]);
# 20150129 - case insensitive for PROC
sub register_procedure {
    my $self  = shift;
    my %param = @_;
    my $proc  = lc($param{PROC});
    my $spec  = $param{SPEC};

    $self->_check_data_type($_) for @$spec;
   
    $registeredProc{$proc}{spec} = $spec;

    return $self;
}

# inject test data
sub inject {
    my $self  = shift;
    my @procs;
    if (@_) {
        for (@_) {
            my $proc = lc($_);
            confess "PROC[$proc] has not been registered!"
                if not exists $registeredProc{$proc};
            push @procs, $proc;
        }
    } else {
        @procs = grep { exists $registeredProc{$_}{spec} }
                 keys %registeredProc;
    }
    for (@procs) {
        $self->register_testdata(
            PROC => $_,
            DATA => dclone($registeredProc{$_}{spec}),
        );
    }
    return $self;
}

# Register the test data for the procedure
# $self->register_testdata(PROC=>$proc, DATA=>[]);
# 20150129 - case insensitive for PROC
sub register_testdata {
    my $self  = shift;
    my %param = @_;
    my ($uuid,$data) = $self->serialize($param{DATA});
    $registeredProc{lc($param{PROC})}{testdata}{$uuid} = $data; 
}

sub show_testdata {
    print Dumper \%registeredProc;
    return shift;
}

# Clean the test data
# Clean all : $self->clean_testdata()
# Clean one : $self->clean_testdata($proc);
sub clean_testdata {
    my $self = shift;
    for my $proc ( @_ ? @_ : keys %registeredProc ) {
        delete $registeredProc{$proc}{testdata}
            if exists $registeredProc{$proc};
    }
    return $self;
}

# Mock the execute_procedure in dbms.pm
# 20150129 - case insensitive PROC
sub execute_procedure {
    my $self  = shift;
    my %inParam = @_;
    
    my $proc  = lc($inParam{PROC});
    my $param = $inParam{PARAM};

    # Get the utid to find the testData
    my @data;
    for my $p (@$param) {
        next if !defined($p) || $p eq '__CURSOR__' || $p eq '__CLOB__';
        if (ref($p)) {
            push @data, OUT();
        }
        else {
            push @data, IN($p);
        }
    }
    my ($utid,undef) = $self->serialize(\@data);

    return 0 if not exists $registeredProc{$proc}{testdata}{$utid};

    #! replicated data in case we touch it by mistake
    my $testData = dclone($registeredProc{$proc}{testdata}{$utid});

    for (my $placeholder = 0; @$param; $placeholder++) {
        my $p = shift @$param;
        if (ref($p)) {
            $$p = $testData->[$placeholder]->val() 
                if ref($testData->[$placeholder]) eq 'dataOUT';
        }
        elsif ($p eq '__CURSOR__'){
            $p= shift @$param;
            $$p = $testData->[$placeholder] 
                if ref($testData->[$placeholder]) eq 'dataCSR';
        }
        elsif ($p eq '__CLOB__'){
            $p= shift @$param;
            $$p = $testData->[$placeholder]->val()
                if ref($testData->[$placeholder]) eq 'dataOUT';
        }
    }

    return 1;
}

# check the validation of data type
# return the type
sub _check_data_type {
    my $self = shift;
    my $data = shift;
    my $type = blessed($data);
    my %STDT = map { $_ => undef } qw{ dataIN dataOUT dataCSR };
    confess "TYPE[$type] is not supported!" if not exists $STDT{$type};
    return $type;
}

# Directly construct the datetype
sub IN  {  dataIN->new(@_) }
sub OUT { dataOUT->new(@_) }
sub CSR { dataCSR->new(@_) }
sub CLB { dataOUT->new(@_) }

AUTOLOAD {
    my $self = shift;
    ( my $method = $AUTOLOAD ) =~ s/.*://;
    return if $method eq 'DESTROY';
    # check if the method can work under $dbh
    # return ture always
    confess "DBI can't do METHOD[$method]" unless DBI::db->can($method);
    return 1;
}

{

  # mock the datatype for IN
  package dataIN;
  sub new {
      my $class = shift;
      my $data  = shift || '';
      bless \$data, $class;
  }
  sub val { 
      my $self = shift;
      if (@_) {
          my $old = $$self;
          $$self  = shift;
          return $old;
      }
      return $$self;
  }

  # mock the datatype for OUT
  # also can be used for CLOB
  package dataOUT;
  sub new { 
      my $class = shift;
      my $data  = shift || '';
      bless \$data, $class;
  }
  sub val { 
      my $self = shift;
      if (@_) {
          my $old = $$self;
          $$self  = shift;
          return $old;
      }
      return $$self;
  }

  # mock the datatype for CURSOR
  package dataCSR;
  use Carp;
  sub new {
      my $class = shift;
      my $data = [ grep _check_rec_type($_), @_ ];
      bless $data, $class;
  }
  sub val {
      my $self = shift;
      if (@_) {
          my $old = [@$self];
          @$self = grep _check_rec_type($_), @_;
          return $old;
      }
      return [@$self];
  }

  sub fetchrow_array {
      my $self = shift;
      return @{ @$self ? shift @$self : [] };
  }

  sub finish {
      my $self = shift;
      $self = [];
      return 1;
  }

  sub _check_rec_type {
      my $rec = shift;
      confess "Data[$rec] is not a ARRAY" if ref($rec) ne 'ARRAY';
      return 1;
  }

}

1;
