# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::IfStatus;
use Moose;
use Manoc::Search::Item::Iface;

extends 'Manoc::Search::Driver';

sub search_note {
    my ( $self, $query, $result ) = @_;
    my ( $it, $e );
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    $it = $schema->resultset('IfStatus')->search(
        description => { '-like' => $pattern },
        { order_by => 'description' }
    );
    while ( $e = $it->next ) {
        my $item = Manoc::Search::Item::Iface->new(
            {
                device    => $e->device_info,
                interface => $e->interface,
                text      => $e->description,
            }
        );
        $result->add_item($item);
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;
