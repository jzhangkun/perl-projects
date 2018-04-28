#!/usr/bin/env perl
use strict;
use warnings;
use CGI qw(:standard);

print header;
my $debug = url_param('_debug');
print "debug mode: $debug\n";

1;
