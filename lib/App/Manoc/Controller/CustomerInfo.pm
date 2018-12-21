package App::Manoc::Controller::CustomerInfo;
#ABSTRACT: CustomerInfo controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::CustomerInfo;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'customerinfo',
        }
    },
    class            => 'ManocDB::CustomerInfo',
    form_class       => 'App::Manoc::Form::CustomerInfo',
    view_object_perm => undef,

    object_list_options => {
        join      => 'ipnetworks',
        distinct  => 1,
        '+select' => [ { count => 'ipnetworks.id' } ],
        '+as'     => [qw/num_ipnetworks/],
    }
);

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    if ( $object->ipnetworks->count > 0 ) {
        $c->flash( error_msg => 'Object is in use. Cannot be deleted.' );
        return;
    }

    return $c->stash->{'object'}->delete;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
