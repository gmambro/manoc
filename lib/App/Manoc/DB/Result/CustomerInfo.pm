package App::Manoc::DB::Result::CustomerInfo;
#ABSTRACT: A model object for information on IP addresses

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('customer_info');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    'name' => {
        data_type   => 'varchar',
        size        => 45,
        is_nullable => 1,
    },
    'phone' => {
        data_type   => 'varchar',
        size        => 30,
        is_nullable => 1,
    },
    'email' => {
        data_type   => 'varchar',
        size        => 45,
        is_nullable => 1,
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    ipnetworks => 'App::Manoc::DB::Result::IPNetwork',
    { 'foreign.customer_info_id' => 'self.id' },
);

=method label

=cut

sub label { shift->name }

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
