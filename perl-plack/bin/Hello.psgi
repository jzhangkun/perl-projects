use strict;
use Plack::Builder;
use Data::Dumper;

my $app = sub {
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 11 ], [ "Hello World" ] ];
};

my $main = sub {
    my $env = shift;
    my $user = $env->{REMOTE_USER};
    if ($user) {
        return [ 200, [], [ "Welcome admin" ] ];
    } else {
        return [ 200, [], [ "Welcome guest" ] ];
    }
};

my $dump = sub {
    my $env = shift;
    return [ 200, [ "Content-Type" => "text/plain" ], [ Dumper $env ] ];
};

builder {
    mount "/hello" => $app;
    mount "/admin" => builder {
        enable "Auth::Basic", authenticator => sub { 
            my ($username, $password) = @_;
            return 1 if $username eq 'zhangkun' && $password eq 'admin';
        };
        mount "/dump" => $dump;
        mount "/home" => $main;
    };
    mount '/guest' => builder {
        mount "/dump" => $dump;
        mount "/home" => $main;
    };
};
