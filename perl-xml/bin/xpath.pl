#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use XML::XPath;
use FindBin qw($Bin);

$XML::XPath::Namespaces = 0;

my ($filename, $xpath, $nodeset, @nodes);
$filename = "$Bin/../testdata/timesheet_namespace.xml";
$xpath = XML::XPath->new(filename => $filename);

$nodeset = $xpath->find('/timesheet/employee/name');
foreach my $node ($nodeset->get_nodelist) {
    print $node->toString(). "\n";
    #print $node->string_value(), "\n";
}

