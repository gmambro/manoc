use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $hwserver_nic1 = $schema->resultset("ServerHWNIC")->create(
    {
        name     => 'eth0',
        macaddr  => '00:11:22:33:44:55',
        serverhw => {
            ram_memory => '16000',
            cpu_model  => 'E1234',
            vendor     => 'Moon',
            model      => 'ShinyBlade',
        },
        nic_type => {
            name => 'FastEthernet 100'
        }
    }
);
ok( $hwserver_nic1, "Create server NIC" );

eval {
    $schema->resultset("CablingMatrix")->create(
        {
            name     => 'eth0',
            macaddr  => '00:11:22:33:44:55',
            serverhw => {
                ram_memory => '16000',
                cpu_model  => 'E1234',
                vendor     => 'HAL',
                model      => 'Cosmo',
            },
            nic_type => {
                name => 'GbEth'
            }
        }
    );
};
ok( $@, "Cannot create server  NIC with duplicated macaddr" );

done_testing;
