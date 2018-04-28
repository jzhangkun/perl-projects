#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use XML::LibXML;
use XML::LibXML::XPathContext;
use constant DEBUG => 1;

my $parser = XML::LibXML->new();
my ($filename, $dom, $nodelist, @nodes);
$filename = "$Bin/../testdata/timesheet_namespace.xml";
$dom = $parser->load_xml(location => $filename) or die $!;

# find nodes with tag name
@nodes = $dom->getElementsByTagName('department');
print "Debug 1:\t" if DEBUG;
for my $node (@nodes) {
    print $node->toString(), "\n";
    #print $node->firstChild->data(), "\n";
}

# LibXML support xmlns (XML Namespace)
# Get to know xmlns from timesheet_namespace.xml
# Because of this, the root element can not be found
$nodelist = $dom->findnodes('/timesheet');
print "Debug 2:\t" if DEBUG;
print "NOT FOUND ROOT ELEMENT\n" unless scalar $nodelist->get_nodelist;

# The common way to solve namespace issue
my $xpc = XML::LibXML::XPathContext->new($dom);
# register the null namespace with prefix-to-url
# 'x' is registered as prefix
# 'fred' is the url from the documents
$xpc->registerNs('x', 'fred');
$nodelist = $xpc->findnodes('/x:timesheet');
print "Debug 3:\t" if DEBUG;
print "FOUND ROOT ELEMENT\n" if scalar $nodelist->get_nodelist;

@nodes = $xpc->findnodes('/x:timesheet/x:employee/x:department');
print "Debug 4:\t" if DEBUG;
for my $node (@nodes) {
    print $node->toString(), "\n";
    #print $node->firstChild->data(), "\n";
}

