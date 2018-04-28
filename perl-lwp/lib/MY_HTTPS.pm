package MY_HTTPS;

use strict;
use warnings;
# Must be loaded in THIS ORDER, very very EARLY
use IO::Socket::SSL ();
use Net::HTTPS ();

use base 'LWP::Protocol::https';

use metaclass;

use LWP::Protocol ();
LWP::Protocol::implementor('https', 'MY_HTTPS');

sub socket_class { 'LWP::Protocol::https::Socket' }

my $ssl_context;

sub use_certs {
    my ($self,$v) = @_;

    my $ssl_version = 'TLSV1_2';

    $ssl_context ||= IO::Socket::SSL::SSL_Context->new(
        SSL_use_cert  => 1,
        SSL_key_file  => $v->{SSL_key_file},
        SSL_cert_file => $v->{SSL_cert_file},
        SSL_version   => $ssl_version,
    );

    __PACKAGE__->meta->add_method('_extra_sock_opts', sub { (
        SSL_reuse_ctx  => $ssl_context,
    )});
}

sub no_certs {
    __PACKAGE__->meta->add_method('_extra_sock_opts', sub { () });
}

1;
