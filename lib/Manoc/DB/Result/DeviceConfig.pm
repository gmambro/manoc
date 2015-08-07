# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DeviceConfig;
use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('device_config');
__PACKAGE__->add_columns(
    'device' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'config' => {
        data_type   => 'text',
        is_nullable => 0
    },
    'prev_config' => {
        data_type   => 'text',
        is_nullable => 1,
    },
    'config_date' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'prev_config_date' => {
        data_type   => 'int',
        size        => 11,
        is_nullable => 1,
    },
    'last_visited' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11,
    }
);

__PACKAGE__->set_primary_key("device");

__PACKAGE__->belongs_to(
    device_info => 'Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.device' }
);

__PACKAGE__->inflate_column(
			    device => {
				   inflate =>
				   sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
				   deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
				  }
			   );



=head1 NAME

Manoc::DB::Result::DeviceConfig - A model object to mantain the devices configuration backup.

=head1 DESCRIPTION

This is an object that represents a CDP entry. It uses DBIx::Class
(aka, DBIC) to do ORM.

=cut

1;
