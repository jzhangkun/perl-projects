package ResponseMapper;
use Moose;
use ValueMapper;

has 'kmapper' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    builder => '_build_default_kmapper',
);

has 'vmapper' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

sub _build_default_kmapper {
    return {
        ra => 'rna',
        rb => 'rnb',
        rc => 'rnc',
    };
}

sub addVmapper {
    my $self = shift;
    my ($key, $mapper) = @_;
    die "not a valid key" if not exists $self->kmapper->{$key};
    die "not a valid mapper" if ref($mapper) ne 'HASH';
    $self->vmapper->{$key} = ValueMapper->new(mapper => $mapper);
}

# input hash
# output hash
sub mapFrom {
    my $self = shift;
    my $input = shift;
    my $output = {};
    while (my ($k, $v) = each %$input) {
        my $nk = exists $self->kmapper->{$k} ? $self->kmapper->{$k} : $k;
        my $nv = exists $self->vmapper->{$k} ? $self->vmapper->{$k}->mapFrom($v) : $v;
        $output->{$nk} = $nv;
    }
    return $output;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
