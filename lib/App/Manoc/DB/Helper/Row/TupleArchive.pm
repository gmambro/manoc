package App::Manoc::DB::Helper::Row::TupleArchive;
#ABSTRACT:  Tuple archive support

use strict;
use warnings;

##VERSION

use Carp 'croak';
use parent 'DBIx::Class';

__PACKAGE__->mk_group_accessors( inherited => '_tuple_archive_columns' );

=head1 DESCRIPTION

Define tuple columns for L<App::Manoc::DB::Helper::ResultSet::TupleArchive>

=head1 SYNOPSYS

 package MySchema::Result::Bar;

 use strict;
 use warnings;

 use parent 'DBIx::Class::Result';

 __PACKAGE__->load_components('+App::Manoc::DB::Helper::Row::TupleArchive');

 # define resultset for using ResultSet::TupleArchive
 __PACKAGE__->resultset_class('MySchema::ResultSet::Bar');

 __PACKAGE__->set_tuple_archive_columns(qw(macaddr ipaddr vlan));

=head1 METHODS

=head2  set_tuple_archive_columns(@column_names)

Define the columns in the tuple

=cut

sub set_tuple_archive_columns {
    my ( $self, @cols ) = @_;

    my $colinfo = $self->columns_info( \@cols );

    for my $col (@cols) {
        if ( $colinfo->{$col}{is_nullable} ) {
            my $source_name = (
                $self->can("source_name") ? $self->source_name :
                    (
                    $self->can("name") ? $self->name :
                        'Unknown source...?'
                    )
            );
            croak(
                sprintf(
                    "Tuple archive columns source '%s' includes the column '%s' which has its "
                        . "'is_nullable' attribute set to true. This is a mistake.",
                    $source_name, $col,
                )
            );
        }
    }

    # check existence of lastseen and firstseen columns
    $self->add_columns(
        'firstseen' => {
            data_type   => 'int',
            is_nullable => 0,
            size        => 11
        },
        'lastseen' => {
            data_type     => 'int',
            default_value => 'NULL',
            is_nullable   => 1,
        },
        'archived' => {
            data_type     => 'int',
            default_value => 0,
            is_nullable   => 0,
            size          => 1
        },
    );

    $self->_tuple_archive_columns( \@cols );
}

=head2 tuple_archive_columns

Get the names of the columns in the tuple

=cut

sub tuple_archive_columns {
    return shift->_tuple_archive_columns;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
