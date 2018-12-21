package App::Manoc::Form::CustomerInfo;

use HTML::FormHandler::Moose;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

##VERSION

has_field 'name' => ( type => 'TextArea' );

has_field 'phone' => ( type => 'Text' );

has_field 'email' => ( type => 'Email', );

has_field 'notes' => ( type => 'TextArea', );

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
