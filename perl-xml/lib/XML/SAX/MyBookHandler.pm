package XML::SAX::MyBookHandler;
use strict;
use warnings;
use parent "XML::SAX::Base";
use Data::Dumper;
use List::MoreUtils qw(any);
use JSON::XS;

my @books;
my $book;
my $tag  = '';

sub getBooks {
    my $self  = shift;
    my %param = @_;
    if ($param{fmt} eq 'json') {
        print "turning into json objct\n";
        my $json = JSON::XS->new()->allow_blessed->convert_blessed();
        return $json->encode(\@books);
    }
    return @books;
}

sub start_element {
    my ($self, $data) = @_;
    print "start_element: $data->{Name}\n";
    if ($data->{Name} eq 'book') {
        $book = Book->new();
    }
    $tag = $data->{Name};
}

sub end_element {
    my ($self, $data) = @_;
    print "end_element $data->{Name}\n";
    if ($data->{Name} eq 'book') {
        push @books, $book;
    }
    # toggling off
    $tag = '';
}

sub characters {
    my ($self, $data) = @_;
    return if $tag eq '';
    print "Data: $data->{Data}\n";
    if (grep { $tag eq $_ } qw(author title year price)) {
        $book->$tag($data->{Data});
    }
}

package Book;
use Moose;
has [qw(author title year price)] => (
    is => 'rw', isa => 'Str'
);

sub TO_JSON {
    return { %{ $_[0] } };
}

1;
