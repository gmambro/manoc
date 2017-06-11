package App::Manoc::Controller::IPBlock;
#ABSTRACT: IPBlock controller
use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

with
    'App::Manoc::ControllerRole::CommonCRUD',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::JSONView';

use App::Manoc::Form::IPBlock;
use App::Manoc::Utils::Datetime qw(str2seconds);

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'ipblock',
        }
    },
    class                   => 'ManocDB::IPBlock',
    form_class              => 'App::Manoc::Form::IPBlock',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [qw( id name from_addr to_addr )],
);

=action view

Override in order to add ARP statistics.

=cut

before 'view' => sub {
    my ( $self, $c ) = @_;

    my $block     = $c->stash->{object};
    my $max_hosts = $block->to_addr->numeric - $block->from_addr->numeric + 1;

    my $query_by_time = { lastseen => { '>=' => time - str2seconds( 60, 'd' ) } };
    my $select_column = {
        columns  => [qw/ipaddr/],
        distinct => 1
    };
    my $arp_60days = $block->arp_entries->search( $query_by_time, $select_column )->count();
    $c->stash( arp_usage60 => int( $arp_60days / $max_hosts * 100 ) );

    my $arp_total = $block->arp_entries->search( {}, $select_column )->count();
    $c->stash( arp_usage => int( $arp_total / $max_hosts * 100 ) );

    my $hosts = $block->ip_entries;
    $c->stash( hosts_usage => int( $hosts->count() / $max_hosts * 100 ) );
};

=action arp

Show ARP activity for the IPBlock

=cut

sub arp : Chained('object') {
    my ( $self, $c ) = @_;

    my $block = $c->stash->{object};

    # override default title
    $c->stash( title => 'ARP activity for block ' . $block->name );

    $c->detach('/arp/list');
}

=action arp_js

Datatable AJAX support for ARP activity list

=cut

sub arp_js : Chained('object') {
    my ( $self, $c ) = @_;

    my $block = $c->stash->{object};
    my $days  = int( $c->req->param('days') );

    my $rs = $block->arp_entries->first_last_seen();
    if ($days) {
        $rs = $rs->search( { lastseen => time - str2seconds( $days, 'd' ) } );
    }
    $c->stash( datatable_resultset => $rs );

    $c->detach('/arp/list_js');
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End: