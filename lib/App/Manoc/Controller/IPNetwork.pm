package App::Manoc::Controller::IPNetwork;
#ABSTRACT: IPNetwork controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'App::Manoc::ControllerRole::CommonCRUD' => { -excludes => ['view'] };

use App::Manoc::Form::IPNetwork;
use App::Manoc::Utils::Datetime qw/str2seconds/;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'ipnetwork',
        }
    },
    class               => 'ManocDB::IPNetwork',
    form_class          => 'App::Manoc::Form::IPNetwork',
    view_object_perm    => undef,
    object_list_options => {
        prefetch => 'vlan',
        order_by => [ { -asc => 'me.address' }, { -desc => 'me.broadcast' } ]

    }
);

=action view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{object};

    if ( $network->prefix == 32 ) {
        $c->log->debug("/32 network");
        $c->stash( ipaddress      => $network->address );
        $c->stash( network_object => $network );
        $c->detach('/ipaddress/view');
    }

    my $max_hosts = $network->network->num_hosts;

    my $query_by_time = { lastseen => { '>=' => time - str2seconds( 60, 'd' ) } };
    my $select_column = {
        columns  => [qw/ipaddr/],
        distinct => 1
    };
    my $arp_60days = $network->arp_entries->search( $query_by_time, $select_column )->count();
    $c->stash( arp_usage60 => int( $arp_60days / $max_hosts * 100 ) );

    my $arp_total = $network->arp_entries->search( {}, $select_column )->count();
    $c->stash( arp_usage => int( $arp_total / $max_hosts * 100 ) );

    my $hosts = $network->host_entries;
    $c->stash( hosts_usage => int( $hosts->count() / $max_hosts * 100 ) );

}

=action view

=cut

before 'list' => sub {
    my ( $self, $c ) = @_;

    my $object_list = $c->stash->{object_list};
    my %depth;

    # just one loop because we have a sorted list
    for my $n (@$object_list) {
        my $depth;
        if ( $n->parent_id ) {
            $depth = $depth{ $n->parent_id } + 1;
        }
        else {
            # it's a root
            $depth = 0;
        }
        $depth{ $n->id } = $depth;
        $n->{depth} = $depth;
    }
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
