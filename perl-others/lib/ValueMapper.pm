package ValueMapper;
use Moose;

has 'field' => (
    is => 'rw',
    isa => 'Str',
);

has 'mapper' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

# input hash
# output hash
sub mapFrom {
    my $self = shift;
    my $input = shift;
    my $output = exists $self->mapper->{$input} ? $self->mapper->{$input} : $input;
    return $output;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
