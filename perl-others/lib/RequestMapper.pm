package RequestMapper;
use Moose;

has 'kmapper' => (
    is => 'rw',
    isa => 'HashRef',
    builder => '_build_default_kmapper',
);

sub _build_default_kmapper {
    return {
        a => 'na',
        b => 'nb',
        c => 'nc',
    };
}

# input hash
# output hash
sub mapRequest {
    my $input = shift;
    my $output = {};
    while (my ($k, $v) = each %$input) {
        $k = exists $kmapper->($k) ? $kmapper->{$k} : $k;
        $output->{$k} = $v;
    }
    return $output;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
