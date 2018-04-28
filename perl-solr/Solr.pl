#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use WebService::Solr;
use WebService::Solr::Query;

# Solr client
sub getSolrClient {
    # VIP
    my $baseurl = 'http://my-solr-server.com/solr';
    my $msgurl = "$baseurl/your-schema";
    my $solr = WebService::Solr->new($msgurl, {agent => MyClient::SolrAgent->new(keep_alive => 1)});
    # validate to make sure server is up
    if ($solr->ping()) {
        return $solr;
    }
    return;
}

sub querySolr {
    my $msgInfo = shift;

    my $solr = getSolrclient();
    my $namePattern = (split q[[.]] => $msgInfo->{fileName})[0] . '*';
    my $query = WebService::Solr::Query->new({ source_name => \"$namePattern" });
    my %options = (
        fq => [ 
            WebService::Solr::Query->new({ message_type => \'*SQLLDR_IMS' }),
        ],
        fl => 'message_id,message_version,message_created_dtm,source_name',
        #start => 0,
        #rows  => 10,
        sort  => 'message_created_dtm desc',
    );
    my $resp  = $solr->search($query, \%options);

    # for debug
    #my @docs = $resp->docs;
    #print Dumper \@docs;
    #print Dumper $resp->pager;

    # fetch the latest message uuid
    my $messageUUID;
    for my $doc ($resp->docs) {
        $messageUUID = $doc->value_for("message_id");
        last if $messageUUID;
    }
    return $messageUUID;
}

package MyClient::SolrAgent;
use strict;
use warnings;
use LWP::UserAgent;
use base 'LWP::UserAgent';

sub get_basic_credentials {
    my ($self, $realm, $url, $isproxy) = @_;
    return ('username', 'password');
}

