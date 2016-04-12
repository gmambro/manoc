# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::CatalystRole::SessionStore;

use base Catalyst::Plugin::Session::Store;
use strict;
use warnings;

use namespace::autoclean;

use MIME::Base64;
use Storable qw/nfreeze thaw/;

sub get_session_rs {
    my $c = shift;

    return $c->model('ManocDB::Session');
}

sub get_session_data {
    my ( $c, $key ) = @_;

    my $rs = $c->get_session_rs;
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    # expires:sid expects an expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $key = "session:$sid";
        my $session = $rs->find($key);
        $session and return $session->{expires};
    }
    else {
        if (my $data = $rs->find($key)->{session_data}) {
            return thaw( decode_base64($data) );
        }
    }
    return;
}


sub store_session_data {
    my ( $c, $key, $data ) = @_;

    my $rs = $c->get_session_rs;
    
    # expires:sid keys only update the expiration time
    if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
        $rs->search({id => "session:$sid"})
          ->update({expires =>$c->session_expires});
    }
    else {
        my $frozen = encode_base64( nfreeze($data) );
        my $expires = $key =~ /^(?:session|flash):/
                    ? $c->session_expires
                    : undef;
        $rs->update_or_create(
            id => $key,
            expires => $expires,
            session_data => $frozen,
           );
    }
    return;
}

sub delete_session_data {
    my ( $c, $key ) = @_;

    return if $key =~ /^expires/;
    my $rs = $c->get_session_rs;
    $rs->search({id => $key})->delete();

    return;
}

sub delete_expired_sessions {
    my $c = shift;

    my $rs = $c->get_session_rs;
    $rs->search({
        expires =>
          {
              '!='  => undef,
              '<' => time,
          },
       })->delete();

    return;
}


no Moose::Role;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
