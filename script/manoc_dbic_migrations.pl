#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::Manoc::Support;

use App::Manoc;
use App::Manoc::Script::ConfigRole;
use DBIx::Class::Migration::Script;

package App::Manoc::Script::DBICMigrations;
use Moose;
extends 'DBIx::Class::Migration::Script';
with 'App::Manoc::Script::ConfigRole';

has '+schema_class' => ( default => 'App::Manoc::DB' );

has '+dsn' => (
    lazy    => 1,
    default => sub {
        shift->config->{'Model::ManocDB'}->{connect_info}->{dsn};
    }
);

no Moose;

package main;

App::Manoc::Script::DBICMigrations->run_with_options();
