package App::Manoc::Controller::Device;
#ABSTRACT: Device Controller
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 CONSUMED ROLES

=for :list
* App::Manoc::ControllerRole::CommonCRUD
* App::Manoc::ControllerRole::JSONView
* App::Manoc::ControllerRole::CSVView

=cut

with
    "App::Manoc::ControllerRole::CommonCRUD",
    "App::Manoc::ControllerRole::JSONView" => { -excludes => 'get_json_object', },
    "App::Manoc::ControllerRole::CSVView";

use Text::Diff;

use App::Manoc::Form::Device::Edit;
use App::Manoc::Form::DeviceNWInfo;
use App::Manoc::Form::Uplink;
use App::Manoc::Form::Device::Decommission;

use App::Manoc::Netwalker::Config;
use App::Manoc::Netwalker::ControlClient;

# moved  App::Manoc::Netwalker::DeviceUpdater to conditional block in refresh
# where we need it

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'device',
        }
    },
    class            => 'ManocDB::Device',
    form_class       => 'App::Manoc::Form::Device::Edit',
    view_object_perm => undef,

    object_list_options => {
        prefetch => [ { 'rack' => 'building' }, 'mng_url_format', 'hwasset', 'netwalker_info', ]
    },

    edit_page_title   => 'Edit device',
    create_page_title => 'New device',
);

=action view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};

    # uplinks
    $c->stash( uplinks => [ map { $_->interface } $device->uplinks->all() ] );

    #Unused interfaces
    my @unused_ifaces = $c->model('ManocDB::IfStatus')->search_unused( $device->id );
    $c->stash( unused_ifaces => \@unused_ifaces );

    # prepare template
    $c->stash( template => 'device/view.tt' );
}

=action ifstatus

Called via xhr by view

=cut

sub ifstatus : Chained('object') : PathPart('ifstatus') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $id     = $device->id;

    # prefetch notes
    my %if_notes = map { $_->interface => 1 } $device->ifnotes;

    # prefetch interfaces last activity
    my %if_last_mat;
    my ( $e, $it );
    $it = $c->model('ManocDB::IfStatus')->search_mat_last_activity($id);
    while ( $e = $it->next ) {
        $if_last_mat{ $e->interface } = $e->get_column('lastseen');
    }

    my @iface_info;

    # fetch ifstatus and build result array
    my @ifstatus = $device->ifstatus;
    foreach my $r (@ifstatus) {
        my ( $controller, $port ) = split /[.\/]/, $r->interface;
        my $lc_if = lc( $r->interface );

        push @iface_info, {
            controller   => $controller,                                  # for sorting
            port         => $port,                                        # for sorting
            interface    => $r->interface,
            speed        => $r->speed || 'n/a',
            up           => $r->up || 'n/a',
            up_admin     => $r->up_admin || '',
            duplex       => $r->duplex || '',
            duplex_admin => $r->duplex_admin || '',
            cps_enable   => $r->cps_enable && $r->cps_enable eq 'true',
            cps_status   => $r->cps_status || '',
            cps_count    => $r->cps_count || '',
            description  => $r->description || '',
            vlan         => $r->vlan || '',
            last_mat     => $if_last_mat{ $r->interface },
            has_notes    => ( exists( $if_notes{$lc_if} ) ? 1 : 0 ),
        };
    }
    @iface_info =
        sort { $a->{controller} cmp $b->{controller} || $a->{port} cmp $b->{port} } @iface_info;

    $c->stash->{no_wrapper} = 1;
    $c->stash->{iface_info} = \@iface_info;
}

=action neighs

Called via xhr by view

=cut

sub neighs : Chained('object') : PathPart('neighs') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};

    my $time_limit = $c->config->{Device}->{cdp_age} || 3600 * 12;    #12 hours

    my @neighs =
        map +{
        expired        => time - $_->last_seen > $time_limit,
        local_iface    => $_->from_interface,
        to_device      => $_->to_device,
        to_device_info => $_->to_device_info,
        remote_id      => $_->remote_id,
        remote_type    => $_->remote_type,
        date           => $_->last_seen,
        },
        $device->neighs( {}, { prefetch => 'to_device_info' } )->all();

    $c->stash->{no_wrapper} = 1;
    $c->stash->{neighs}     = \@neighs;
}

=action ssids

Called via xhr by view

=cut

sub ssids : Chained('object') : PathPart('ssids') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};

    # wireless info

    # ssid
    my @ssid_list = map +{
        interface => $_->interface,
        ssid      => $_->ssid,
        broadcast => $_->broadcast ? 'yes' : 'no',
        channel   => $_->channel
        },
        $device->ssids;
    $c->stash->{ssid_list} = \@ssid_list;

    $c->stash->{no_wrapper} = 1;
}

=action dot11clients

Called via xhr by view

=cut

sub dot11clients : Chained('object') : PathPart('dot11clients') : Args(0) {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};

    my @dot11_clients = map +{
        ssid    => $_->ssid,
        macaddr => $_->macaddr,
        ipaddr  => $_->ipaddr,
        vlan    => $_->vlan,
        quality => $_->quality . '/100',
        state   => $_->state,
        },
        $device->dot11clients;
    $c->stash->{dot11_clients} = \@dot11_clients;

    $c->stash->{no_wrapper} = 1;
}

=action refresh

=cut

sub refresh : Chained('object') : PathPart('refresh') : Args(0) {
    my ( $self, $c ) = @_;
    my $device_id = $c->stash->{object}->id;

    my $config = App::Manoc::Netwalker::Config->new( $c->config->{Netwalker} || {} );
    my $client = App::Manoc::Netwalker::ControlClient->new( config => $config );

    my $status = $client->enqueue_device($device_id);

    if ( !$status ) {
        $c->flash( error_msg => "An error occurred while scheduling device refresh" );
    }
    else {
        $c->flash( message => "Device refresh scheduled" );
    }

    $c->response->redirect( $c->uri_for_action( '/device/view', [$device_id] ) );
    $c->detach();
}

=action uplinks

=cut

sub uplinks : Chained('object') : PathPart('uplinks') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{'object'};
    $c->require_permission( $device, 'edit' );

    my $form = App::Manoc::Form::Uplink->new( { device => $device, ctx => $c } );

    if ( $device->ifstatus->count() == 0 ) {
        $c->flash( error_msg => 'No known interfaces on this device' );
        $c->uri_for_action( 'device/view', [ $device->id ] );
        $c->detach();
    }
    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return
        unless $form->process( params => $c->req->parameters, );

    $c->response->redirect( $c->uri_for_action( 'device/view', [ $device->id ] ) );
    $c->detach();
}

=action nwinfo

=cut

sub nwinfo : Chained('object') : PathPart('nwinfo') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'netwalker_config' );

    my $device_id = $c->stash->{object_pk};

    my $nwinfo = $c->model('ManocDB::DeviceNWinfo')->find($device_id);
    $nwinfo or $nwinfo = $c->model('ManocDB::DeviceNWInfo')->new_result( {} );

    my $form = App::Manoc::Form::DeviceNWInfo->new(
        {
            device => $device_id,
            ctx    => $c,
        }
    );
    $c->stash( form => $form );
    return unless $form->process(
        params => $c->req->params,
        item   => $nwinfo
    );

    $c->response->redirect( $c->uri_for_action( 'device/view', [$device_id] ) );
    $c->detach();
}

=action show_config

Show running configuration

=cut

sub show_config : Chained('object') : PathPart('config') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{object};
    $c->require_permission( $device, 'show_config' );

    my $config = $device->config;

    my $prev_config = $config->prev_config;
    my $curr_config = $config->config;

    #Get diff and modify diff string
    my $diff = diff( \$prev_config, \$curr_config );

    #Clear "@@...@@" stuff
    $diff =~ s/@@[^@]*@@/<hr>/g;

    #Insert HTML "font" tag to color "+" and "-" rows
    $diff =~ s/^\+(.*)$/<font color=\"green\"> $1<\/font>/mg;
    $diff =~ s/^\-(.*)$/<font color=\"red\"> $1<\/font>/mg;

    #Prepare template
    $c->stash(
        config => $config,
        diff   => $diff,
    );
    $c->stash( template => 'device/show_run.tt' );

}

=action create

Override in order to manage rack parameter.

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $rack_id = $c->req->query_parameters->{'rack'};
    if ( defined($rack_id) ) {
        $c->log->debug("new device in rack $rack_id") if $c->debug;
        $c->stash( form_defaults => { rack => $rack_id } );
    }

};

=action decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::Device::Decommission->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action( 'device/view', [ $c->stash->{object_pk} ] ) );
    $c->detach();
}

=action restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{object};
    $c->require_permission( $device, 'edit' );

    if ( !$device->decommissioned ) {
        $c->response->redirect( $c->uri_for_action( 'device/view', [ $device->id ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $device->restore;
        $device->update();
        $c->flash( message => "Device restored" );
        $c->response->redirect( $c->uri_for_action( 'device/view', [ $device->id ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore network device',
        confirm_message => 'Restore decommissione device ' . $device->name . '?',
        template        => 'generic_confirm.tt',
    );
}

=action update_from_nwinfo

=cut

sub update_from_nwinfo : Chained('object') : PathPart('from_nwinfo') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{object};
    $c->require_permission( $device, 'edit' );

    my $response = {};
    $response->{success} = 0;

    if ( !$device->decommissioned &&
        defined( $device->netwalker_info ) &&
        $c->req->method eq 'POST' )
    {
        my $nwinfo = $device->netwalker_info;
        my $what   = lc( $c->req->params->{what} );

        if ( $what eq 'name' ) {
            $nwinfo->name and $device->name( $nwinfo->name );
        }
        $device->update();
        $response->{success} = 1;
    }

    $c->stash( json_data => $response );
    $c->forward('View::JSON');
}

=method get_object

Find by id or mng_address.

=cut

sub get_object {
    my ( $self, $c, $id ) = @_;

    my $object = $c->stash->{resultset}->find($id);
    if ( !defined($object) ) {
        $object = $c->stash->{resultset}->find( { mng_address => $id } );
    }
    return $object;
}

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $device = $c->stash->{'object'};
    my $name   = $device->name;

    my $has_related_info = $device->ifstatus->count() ||
        $device->uplinks->count()      ||
        $device->mat_assocs()->count() ||
        $device->dot11assocs->count()  ||
        $device->neighs->count();

    if ($has_related_info) {
        $c->flash(
            error_msg => "Device '$device' has some associated info and cannot be deleted." );
        return;
    }

    return $device->delete;
}

=method get_json_object

=cut

sub get_json_object {
    my ( $self, $c, $device ) = @_;

    my $r = $self->prepare_json_object( $c, $device );
    $r->{rack} = $device->rack->id, return $r;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
