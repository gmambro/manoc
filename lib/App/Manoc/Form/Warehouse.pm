package App::Manoc::Form::Warehouse;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::Horizontal', 'App::Manoc::Form::TraitFor::SaveButton';

has '+name' => ( default => 'form-warehouse' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Name',
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
    required     => 0,
    label        => 'Building',
);

has_field 'floor' => (
    type     => 'Integer',
    required => 0,
    label    => 'Floor',
);

has_field 'room' => (
    type     => 'Text',
    size     => 32,
    required => 0
);

has_field 'notes' => (
    type     => 'TextArea',
    label    => 'Notes',
    required => 0,
    row      => 3,
);

has '+dependency' => (
    default => sub {
        [ [ 'floor', 'building' ], ];
    }
);

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings =
        $self->schema->resultset('Building')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@buildings) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
