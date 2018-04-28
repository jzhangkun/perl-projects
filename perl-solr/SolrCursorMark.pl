#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use WebService::Solr;
use WebService::Solr::Query;
use LWP::UserAgent;


my $baseurl = 'http://server.com/solr';
my $msgurl = "$baseurl/Schema";

my $solr = WebService::Solr->new($msgurl, {agent => MyClient::SolrAgent->new(keep_alive => 1)});

my $query = WebService::Solr::Query->new( { source_name => \'WMI_Inventory*' } );

# use cursor mark to fetch and iterate
my %options = (
    'fq' => [ WebService::Solr::Query->new({
         message_created_dtm => { -range => ['2016-10-14T00:00:01Z','2016-10-14T11:59:59Z' ] } 
    })],
    'fl' => 'message_id,source_name,partner_org_id',
    start => 0,
    rows  => 10,
    cursorMark => '*',
);

#my $resp  = $solr->search($query, \%options);
#my $content = $resp->content;
#my $pager = $resp->pager();
#my $total = $pager->total_entries;

my $is_done = 0;
my @messages;
my %messageId;
my $i = 1;
while (!$is_done) {
    my ($nextCursorMark, $docs) = fetchSolrCursorMark($query, \%options);
    $is_done = 1 if $i++ == 5; 
    for my $doc (@$docs) {
        push @messages, $doc->value_for('message_id');
        $messageId{ $doc->value_for('message_id') }++;
    }
    if ($nextCursorMark eq $options{cursorMark}) {
        $is_done = 1;
    } else {
        $options{cursorMark} = $nextCursorMark;
    }
}
print "get: ", scalar(@messages), "\n";
print "hash: ", scalar(keys %messageId), "\n";
#print Dumper \@messages;
exit;

sub fetchSolrCursorMark {
    my ($query, $options) = @_;
    $options{cursorMark} = '*'
        if not exists $options{cursorMark};
    my $resp = $solr->search($query,$options);
    my ($nextCursorMark, @docs);
    if ($resp->ok) {
        my $content = $resp->content;
        $nextCursorMark = $content->{nextCursorMark};
        @docs = $resp->docs;
    }
    return ($nextCursorMark, \@docs);
}

{

package MyClient::SolrAgent;
use strict;
use warnings;
use base 'LWP::UserAgent';

sub get_basic_credentials {
    my ($self, $realm, $url, $isproxy) = @_;
    return ('username', 'password')
}

1;

}
