# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Device;
use Moose;
use Manoc::Search::Item::Device;

extends 'Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    return $self->search_device( $query, $result );
}

sub search_device {
    my ( $self, $query, $result ) = @_;
    my $rs = $self->_search_id($query);

    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->id
            }
        );
        $result->add_item($item);
    }

    $rs = $self->_search_name($query);
    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->name
            }
        );
        $result->add_item($item);
    }
}

sub search_ipaddr {
    my ( $self, $query, $result ) = @_;
    my $rs = $self->_search_id($query);

    while ( my $e = $rs->next ) {
        my $item = Manoc::Search::Item::Device->new(
            {
                device => $e,
                match  => $e->id
            }
        );
        $result->add_item($item);
    }
}

sub _search_id {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Device')->search(
        'id' => { -like => $pattern },
        { order_by => 'name' }
    );
}

sub _search_name {
    my ( $self, $query ) = @_;
    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    return $schema->resultset('Device')->search(
        'name' => { -like => $pattern },
        { order_by => 'name' }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;