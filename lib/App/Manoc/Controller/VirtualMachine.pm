package App::Manoc::Controller::VirtualMachine;
#ABSTRACT: VirtualMachine controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::VirtualMachine;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'virtualmachine',
        }
    },
    class      => 'ManocDB::VirtualMachine',
    form_class => 'App::Manoc::Form::VirtualMachine',

    create_page_title => 'Create virtual machine',
    edit_page_title   => 'Edit virtual machine',

);

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    if ( my $nwinfo_id = $c->req->query_parameters->{'nwinfo'} ) {
        my $nwinfo = $c->model('ManocDB::ServerNWInfo')->find($nwinfo_id);
        if ($nwinfo) {
            my %cols;
            $cols{vcpus}      = $nwinfo->n_procs;
            $cols{ram_memory} = $nwinfo->ram_memory;
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
    if ( $object->decommissioned ) {
        $c->flash( message => "Cannot edit a decommissioned virtual machine" );
        $c->res->redirect( $c->uri_for_action( 'virtualmachine/view', [$object_pk] ) );
        $c->detach();
    }
};

=action decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( 'virtualmachine', 'edit' );

    if ( $object->in_use ) {
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $object->decommission;
        $object->update();
        $c->flash( message => "Virtual machine decommissioned" );
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Decommission virtual machine',
        confirm_message => 'Decommission virtual machine ' . $object->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=action restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $vm = $c->stash->{object};
    $c->require_permission( $vm, 'edit' );

    if ( !$vm->decommissioned ) {
        $c->response->redirect( $c->uri_for_action( 'virtualmachine/view', [ $vm->id ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $vm->restore;
        $vm->update();
        $c->flash( message => "Virtual machine restored" );
        $c->response->redirect( $c->uri_for_action( 'virtualmachine/view', [ $vm->id ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore  virtual machine',
        confirm_message => 'Restore decommissioned virtual machine ' . $vm->name . '?',
        template        => 'generic_confirm.tt',
    );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
