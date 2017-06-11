package App::Manoc::Search::Driver::WinLogon;

use Moose;

##VERSION

extends 'App::Manoc::Search::Driver';

use App::Manoc::Search::Item::IpAddr;

sub search_logon {
    my ( $self, $query, $result ) = @_;

    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;
    my ( $e, $it );

    my $conditions = {};
    $conditions->{'user'} = { '-like', $pattern };
    if ( $query->limit ) {
        $conditions->{lastseen} = { '>=', $query->start_date };
    }

    $it = $schema->resultset('WinLogon')->search(
        $conditions,
        {
            select   => [ 'user', 'ipaddr', { max => 'lastseen' } ],
            as       => [ 'user', 'ipaddr', 'lastseen' ],
            group_by => 'ipaddr',
        }
    );

    while ( my $e = $it->next ) {
        my $item = App::Manoc::Search::Item::IpAddr->new(
            {
                match     => lc( $e->user ),
                addr      => $e->ipaddr->address,
                timestamp => $e->get_column('lastseen'),
            }
        );
        $result->add_item($item);
    }
}