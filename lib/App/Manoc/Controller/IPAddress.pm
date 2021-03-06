package App::Manoc::Controller::IPAddress;
#ABSTRACT: Controller for showing info on IP addresses
use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::IPAddress::IPv4;
use App::Manoc::Utils::IPAddress qw(check_addr);
use App::Manoc::Form::IPAddressInfo;

BEGIN { extends 'Catalyst::Controller'; }

use strict;

=action base

=cut

sub base : Chained('/') PathPart('ip') CaptureArgs(1) {
    my ( $self, $c, $address ) = @_;

    if ( !check_addr($address) ) {
        $c->detach('/error/http_404');
    }

    $c->stash(
        ipaddress => App::Manoc::IPAddress::IPv4->new($address),
        object    => $c->model('ManocDB::IPAddressInfo')->find( { ipaddr => $address } )
    );
}

=action view

=cut

sub view : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $ipaddress = $c->stash->{ipaddress};

    $c->stash( devices =>
            $c->model('ManocDB::Device')->search( { mng_address => $ipaddress->padded } )
            ->first );

    $c->stash(
        ipblocks => [ $c->model('ManocDB::IPBlock')->including_address_ordered($ipaddress) ] );

    $c->stash(
        networks => [ $c->model('ManocDB::IPNetwork')->including_address_ordered($ipaddress) ]
    );

    $c->stash(
        arp_entries => [ $c->model('ManocDB::Arp')->search_by_ipaddress_ordered($ipaddress) ] );

    $c->stash(
        servers => [
            $c->model('ManocDB::Server')->search(
                {
                    -or => [
                        { address            => $ipaddress->padded },
                        { 'addresses.ipaddr' => $ipaddress->padded },
                    ]
                },
                { join => 'addresses' }
            )
        ],
    );

    $c->stash(
        hostnames => [
            $c->model('ManocDB::WinHostname')->search(
                { ipaddr   => $ipaddress->padded },
                { order_by => { -desc => [ 'lastseen', 'firstseen' ] } }
            )
        ],
    );

    $c->stash(
        logons => [
            $c->model('ManocDB::WinLogon')->search(
                { ipaddr   => $ipaddress->padded },
                { order_by => { -desc => ['lastseen'] } },
            )
        ],
    );

    $c->stash(
        reservations => [
            $c->model('ManocDB::DHCPReservation')->search( { ipaddr => $ipaddress->padded } )
        ],
    );

    $c->stash( leases =>
            [ $c->model('ManocDB::DHCPLease')->search( { ipaddr => $ipaddress->padded } ) ], );
}

=action edit

=cut

sub edit : Chained('base') PathPart('edit') Args(0) {
    my ( $self, $c ) = @_;

    my $item      = $c->stash->{object};
    my $ipaddress = $c->stash->{ipaddress};
    if ($item) {
        $c->require_permission( $item, 'edit' );
    }
    else {
        $item = $c->model('ManocDB::IPAddressInfo')->new_result( {} );
        $item->ipaddr($ipaddress);
        $c->require_permission( $item, 'create' );
    }

    my $form = App::Manoc::Form::IPAddressInfo->new( ipaddr => $ipaddress->address );
    $c->stash( form => $form );

    return unless $form->process(
        params => $c->req->params,
        item   => $item
    );

    $c->res->redirect( $c->uri_for_action( 'ipaddr/view', [ $ipaddress->address ] ) );
    $c->detach();
}

=action delete

=cut

sub delete : Chained('base') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $item      = $c->stash->{object};
    my $ipaddress = $c->stash->{ipaddress};

    my $redirect_url = $c->uri_for_action( 'ipaddr/view', [ $ipaddress->address ] );
    unless ($item) {
        $c->res->redirect($redirect_url);
        $c->detach;
    }

    if ( $c->req->method eq 'POST' ) {
        $item->delete;
        $c->res->redirect($redirect_url);
        $c->detach;
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

__PACKAGE__->meta->make_immutable;

1;
