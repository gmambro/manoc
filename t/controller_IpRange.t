use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'Manoc' }
BEGIN { use_ok 'Manoc::Controller::IpRange' }

ok( request('/iprange')->is_success, 'Request should succeed' );
done_testing();
