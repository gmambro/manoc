package App::Manoc::Form::LanSegment;
#ABSTRACT: Manoc Form for editing lan segment.

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

use namespace::autoclean;

has '+item_class' => ( default => 'LanSegment' );
has '+name'       => ( default => 'form-lansegment' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
);

has_field 'vtp_domain' => (
    type     => 'Text',
    required => 0,
);

has_field 'notes' => ( type => 'TextArea' );

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
