#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;

#no warnings 'redefine';
#sub LWP::UserAgent::get_basic_credentials {
#    warn @_;  # get realm
#}

my $username = 'zhangkun';
my $password = 'admin';
my $ua  = LWP::UserAgent->new();
my $url = URI->new('http://127.0.0.1:3000/admin/dump');
$ua->credentials($url->host.':'.$url->port, 'restricted area', $username, $password);
my $resp = $ua->get($url);

if ($resp->is_success) {
    print "Responsed\n",
            $resp->as_string, "\n";
} else {
    print "Failed\n",
            $resp->status_line, "\n";
}
