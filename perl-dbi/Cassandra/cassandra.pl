#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use DBI;
use DBD::Cassandra;

# single host
#my $dns = 'dbi:Cassandra:keyspace=mySchema;host=ip1;port=9042';
# cluster
my $dns = 'dbi:Cassandra:keyspace=mySchema;hosts=ip1,ip2;port=9042';
my ($username, $password) = ('username', 'password');

print "connecting......\n";
my $dbh = DBI->connect($dns, $username, $password, { RaiseError => 1 }) or die $DBI::errstr;

my $cql = 'select * from table';
my $sth = $dbh->prepare($cql);
$sth->execute();
my $data = $sth->fetchrow_arrayref;

    
$dbh->disconnect;
