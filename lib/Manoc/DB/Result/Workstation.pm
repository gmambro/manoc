# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Workstation;

use strict;
use warnings;

use parent 'Manoc::DB::Result';

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('workstations');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    hostname => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 128,
    },

    ethernet_static_ipaddr => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },

    ethernet_reservation_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    wireless_static_ipaddr => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },

    wireless_reservation_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    os => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    os_ver => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    workstationhw_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    decommissioned => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },

    decommission_ts => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },

);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/hostname/] );

__PACKAGE__->belongs_to(
    workstationhw => 'Manoc::DB::Result::WorkstationHW',
    'workstationhw_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    ethernet_reservation => 'Manoc::DB::Result::DHCPReservation',
    'ethernet_reservation_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->belongs_to(
    wireless_reservation => 'Manoc::DB::Result::DHCPReservation',
    'wireless_reservation_id',
    {
        join_type => 'left',
    }
);

__PACKAGE__->has_many(
    installed_sw_pkgs => 'Manoc::DB::Result::WorkstationSWPkg',
    'workstation_id'
);

__PACKAGE__->many_to_many(
    software_pkgs => 'installed_sw_pkgs',
    'software_pkg'
);

=head2 decommission([timestamp=>$timestamp])

Set decommissioned to true, update timestamp.


=cut

sub decommission {
    my $self      = shift;
    my %args      = @_;
    my $timestamp = $args{timestamp} // time();

    $self->decommissioned and return 1;

    $self->decommissioned(1);
    $self->decommission_ts($timestamp);
    $self->workstationhw_id(undef);
    $self->update();
}

=head2 restore

=cut

sub restore {
    my $self = shift;

    return unless $self->decommissioned;

    $self->decommissioned(0);
    $self->decommission_ts(undef);

    $self->update;
}

=head2 label

=cut

sub label { shift->hostname }

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
