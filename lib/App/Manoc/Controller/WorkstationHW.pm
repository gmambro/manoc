package App::Manoc::Controller::WorkstationHW;
#ABSTRACT: WorkstationHW controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends "App::Manoc::ControllerBase::CRUD" }

with "App::Manoc::ControllerRole::JQDatatable";

use App::Manoc::Form::WorkstationHW;
use App::Manoc::Form::CSVImport::WorkstationHW;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'workstationhw',
        }
    },
    class            => 'ManocDB::WorkstationHW',
    form_class       => 'App::Manoc::Form::WorkstationHW',
    view_object_perm => undef,

    create_page_title => 'Create workstation hardware',
    edit_page_title   => 'Edit workstation hardware',

    object_list_options => {
        prefetch => [ { 'hwasset' => 'building' }, 'workstation' ]
    },

    datatable_row_callback => 'datatable_row',
    datatable_columns      => [
        qw(hwasset.inventory hwasset.type hwasset.vendor hwasset.model hwasset.serial workstation.name)
    ],
    datatable_search_columns =>
        [qw(hwasset.serial hwasset.vendor hwasset.model hwasset.inventory workstation.name)],
    datatable_search_options  => { prefetch => [ 'hwasset', 'workstation' ] },
    datatable_search_callback => 'datatable_search_cb',

);

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    if ( my $copy_id = $c->req->query_parameters->{'copy'} ) {
        my $original = $c->stash->{resultset}->find($copy_id);
        if ($original) {
            $c->log->debug("copy workstation from $copy_id");
            my %cols = $original->get_columns;
            delete $cols{'hwasset_id'};
            delete $cols{'id'};
            foreach (qw(model vendor)) {
                $cols{$_} = $original->hwasset->get_column($_);
            }

            $c->stash( form_defaults => \%cols );
        }
    }

};

=action edit

=cut

before 'edit' => sub {
    my ( $self, $c ) = @_;

    my $object    = $c->stash->{object};
    my $object_pk = $c->stash->{object_pk};

    # decommissioned objects cannot be edited
    if ( $object->is_decommissioned ) {
        $c->res->redirect( $c->uri_for_action( 'workstationhw/view', [$object_pk] ) );
        $c->detach();
    }
};

=action import_csv

Import a workstation hardware list from a CSV file

=cut

sub import_csv : Chained('base') : PathPart('importcsv') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( 'workstationhw', 'create' );
    my $rs = $c->stash->{resultset};

    my $upload;
    $c->req->method eq 'POST' and $upload = $c->req->upload('file');

    my $form = App::Manoc::Form::CSVImport::WorkstationHW->new(
        ctx       => $c,
        resultset => $rs,
    );
    $c->stash->{form} = $form;

    my %process_params;
    $process_params{params} = $c->req->parameters;
    $upload and $process_params{params}->{file} = $upload;
    my $process_status = $form->process(%process_params);

    return unless $process_status;
}

=action decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( 'workstationhw', 'edit' );

    if ( $object->in_use ) {
        $c->response->redirect(
            $c->uri_for_action( 'workstationhw/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $object->decommission;
        $object->update();
        $c->flash( message => "Workstation hardware decommissioned" );
        $c->response->redirect(
            $c->uri_for_action( 'workstationhw/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Decommission workstation hardware',
        confirm_message => 'Decommission workstation hardware ' . $object->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=action restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $workstationhw = $c->stash->{object};
    $c->require_permission( $workstationhw, 'edit' );

    my $object_url = $c->uri_for_action( 'workstationhw/view', [ $workstationhw->id ] );

    if ( !$workstationhw->is_decommissioned ) {
        $c->response->redirect($object_url);
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $workstationhw->restore;
        $workstationhw->update();
        $c->flash( message => "Asset restored" );
        $c->response->redirect($object_url);
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore workstation hardware',
        confirm_message => 'Restore ' . $workstationhw->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=method datatable_search_cb

=cut

sub datatable_search_cb {
    my ( $self, $c, $filter, $attr ) = @_;

    my $extra_filter = {};

    my $status = $c->request->param('search_status');
    if ( defined($status) ) {
        $status eq 'd' and
            $extra_filter->{location} =
            App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED;
        $status eq 'w' and
            $extra_filter->{location} = App::Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE;
        $status eq 'u' and
            $extra_filter->{location} = [
            -and => { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE }
            ];
    }

    my $warehouse = $c->request->param('search_warehouse');
    if ( defined($warehouse) ) {
        $extra_filter->{warehouse_id} = $warehouse;
    }

    %$extra_filter and
        $filter = { -and => [ $filter, $extra_filter ] };

    return ( $filter, $attr );
}

=method datatable_row

=cut

sub datatable_row {
    my ( $self, $c, $row ) = @_;

    my $json_data = {
        inventory   => $row->inventory,
        vendor      => $row->vendor,
        model       => $row->model,
        serial      => $row->serial,
        display     => $row->display,
        location    => $row->display_location,
        href        => $c->uri_for_action( 'workstationhw/view', [ $row->id ] )->as_string,
        workstation => undef,
    };
    if ( my $wks = $row->workstation ) {
        $json_data->{workstation} = {
            hostname => $wks->name,
            href     => $c->uri_for_action( 'workstation/view', [ $wks->id ] )->as_string,
        };
    }

    return $json_data;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
