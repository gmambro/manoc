package App::Manoc::Search::Driver::HWAsset;

use Moose;

##VERSION

use App::Manoc::Search::Item::HWAsset;

extends 'App::Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my $schema  = $self->engine->schema;
    my $pattern = $query->sql_pattern;

    foreach my $col (qw (serial inventory)) {
        my $rs = $schema->resultset('HWAsset')
            ->search( { $col => { -like => $pattern } }, { order_by => 'name' } );

        while ( my $e = $rs->next ) {
            my $item = App::Manoc::Search::Item::HWAsset->new(
                {
                    hwasset => $e,
                    match   => $e->$col,
                }
            );
            $result->add_item($item);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
