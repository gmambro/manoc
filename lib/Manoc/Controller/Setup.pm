# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Setup;
use Moose;
use namespace::autoclean;

use SQL::Translator;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Setup - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 database

=cut

sub database : Args(0) {
    my ($self, $c) = @_;
    $c->log->debug("What now?");

    try {
        $c->stash(db_config => $c->model('ManocDB')->connect_info->{dsn});
        $c->stash(db_check1 => $c->model('ManocDB')->connect);
        $c->stash(db_check2 => $c->model('ManocDB::User')->count());
    } catch {
        $c->stash(message => 'error');
    };


    $c->stash(template => 'setup/database.tt');
    $c->forward('View::TTBare');

}

sub create_schema : Args(0) {
    my $self = shift;

    my $translator = SQL::Translator->new(
        debug          => $self->debug,
        trace          => $self->trace,
        no_comments    => !$self->comments,
        show_warnings  => $self->show_warnings,
        add_drop_table => $self->add_drop_table,
        validate       => $self->validate,
        parser_args    => { dbic_schema => 'Manoc::DB', },
    );

    $translator->parser('SQL::Translator::Parser::DBIx::Class');

    my $be = $self->backend;
    $translator->producer("SQL::Translator::Producer::$be");

    my $output = $translator->translate() or die "Error: " . $translator->error;

    print $output;
    return 0;
}


=head1 AUTHOR

Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
