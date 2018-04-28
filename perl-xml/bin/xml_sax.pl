#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use XML::SAX;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::SAX::MyBookHandler;

# get a list of known parsers
my $parsers = XML::SAX->parsers();
print Dumper $parsers;

my $testdata_dir = "$Bin/../testdata";

my $handler = XML::SAX::MyBookHandler->new();
my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
$p->parse_file("$testdata_dir/book.xml");

my $books_str = $handler->getBooks(fmt => 'json');
print $books_str, "\n";
