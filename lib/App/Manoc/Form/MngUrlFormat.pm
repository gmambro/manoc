package App::Manoc::Form::MngUrlFormat;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

has '+name' => ( default => 'form-mngurlformat' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /^\w+$/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'format' => ( type => 'Text' );

1;
