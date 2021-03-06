package App::Manoc::DB::ResultSet::DiscoverSession;
#ABSTRACT: ResultSet class for DiscoverSession

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use Scalar::Util qw(blessed);

=method including_address($ipaddress)

Return a resultset of all DiscoverSession which include C<$ipaddress> in their
range.

=cut

sub including_address {
    my ( $self, $ipaddress ) = @_;

    if ( blessed($ipaddress) &&
        $ipaddress->isa('App::Manoc::IPAddress::IPv4') )
    {
        $ipaddress = $ipaddress->padded;
    }
    my $rs = $self->search(
        {
            'from_addr' => { '<=' => $ipaddress },
            'to_addr'   => { '>=' => $ipaddress },
        }
    );
    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
