package App::Manoc::Controller::IPAddress;
#ABSTRACT: Controller for showing info on IP addresses
use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::IPAddress::IPv4;
use App::Manoc::Utils::IPAddress qw(check_addr);

BEGIN { extends 'Catalyst::Controller'; }

use strict;

=action base

=cut

sub base : Chained('/') PathPart('ip') CaptureArgs(1) {
    my ( $self, $c, $address ) = @_;

    if ( !check_addr($address) ) {
        $c->detach('/error/http_404');
    }

    $c->stash( ipaddress => App::Manoc::IPAddress::IPv4->new($address), );
}

=action view

=cut

sub view : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $ipaddress = $c->stash->{ipaddress};

    my $devices =
        $c->model('ManocDB::Device')->search( { mng_address => $ipaddress->padded } )->first;
    my $ipblocks = [ $c->model('ManocDB::IPBlock')->including_address_ordered($ipaddress) ];
    my $networks = [ $c->model('ManocDB::IPNetwork')->including_address_ordered($ipaddress) ];
    my $arp_entries = [ $c->model('ManocDB::Arp')->search_by_ipaddress_ordered($ipaddress) ];
    my $servers     = [
        $c->model('ManocDB::Server')->search(
            {
                -or => [
                    { address            => $ipaddress->padded },
                    { 'addresses.ipaddr' => $ipaddress->padded },
                ]
            },
            { join => 'addresses' }
        )
    ];
    my $hostnames = [
        $c->model('ManocDB::WinHostname')->search(
            { ipaddr   => $ipaddress->padded },
            { order_by => { -desc => [ 'lastseen', 'firstseen' ] } }
        )
    ];

    my $logons = [
        $c->model('ManocDB::WinLogon')->search(
            { ipaddr   => $ipaddress->padded },
            { order_by => { -desc => ['lastseen'] } },
        )
    ];
    my $reservations =
        [ $c->model('ManocDB::DHCPReservation')->search( { ipaddr => $ipaddress->padded } ) ];
    my $leases =
        [ $c->model('ManocDB::DHCPLease')->search( { ipaddr => $ipaddress->padded } ) ];

    $c->stash(
        devices     => $devices,
        ipblocks    => $ipblocks,
        networks    => $networks,
        arp_entries => $arp_entries,
        hostnames   => $hostnames,
        logons      => $logons,
        leases      => $leases,
    );

    $c->stash( template => 'ipaddress/view.tt' );
}

__PACKAGE__->meta->make_immutable;

1;
