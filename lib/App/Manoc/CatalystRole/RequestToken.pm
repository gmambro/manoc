package App::Manoc::CatalystRole::RequestToken;
#ABSTRACT: Catalyst plugin for Manoc CSRF support

use Moose::Role;

##VERSION

use namespace::autoclean;

use Digest::SHA1;

has [qw/ token_session_name token_request_name /] => (
    is      => 'ro',
    default => 'csrf_token'
);

has token_length => (
    is      => 'ro',
    isa     => 'Int',
    default => 16,
);

=head1 METHODS

=head2 get_token

Get the current token from session. If not set generate it.

=cut

sub get_token {
    my ($c) = @_;
    return $c->session->{ $c->token_session_name } ||= $c->_generate_token($c);
}

sub _generate_token {
    my ($c) = @_;

    my $seed = join( time, rand(), $$ );

    my $token = Digest::SHA1::sha1_hex($seed);
    $token = substr( $token, 0, $c->token_length );

    $c->log->debug("created request token $token") if $c->debug;
    return $token;
}

=head2 check_token($c, [$token])

Check if the request token is valid. If it is not set load it from $c->req->param

=cut

sub check_token {
    my ( $c, $request_token ) = @_;

    $c->log->debug('validating token') if $c->debug;

    my $session_token = $c->get_token;

    # get token from params
    $request_token ||= $c->req->params->{ $c->token_request_name };

    # try to get token from named forms
    if ( !$request_token ) {
        my $params = $c->req->params;
        while ( my ( $key, $value ) = each(%$params) ) {
            my ( $name, $attr ) = split /\./, $key, 2;

            # only care for named form (i.e. avoid query parameters)
            next unless $attr;

            if ( $attr eq $c->token_request_name ) {
                $request_token = $value;
                $c->log->debug("token found in form $name") if $c->debug;
                last;
            }
        }
    }

    if ( ( $session_token && $request_token ) &&
        $session_token eq $request_token )
    {
        $c->log->debug('token is valid') if $c->debug;
        return 1;
    }
    else {
        $c->log->debug('token is invalid') if $c->debug;
        return 0;
    }
}

=head2 require_valid_token($c, [$token])

Check the request token using check_token. If it's not valid generate
a 403 error.

=cut

sub require_valid_token {
    my ( $c, $token ) = @_;

    if ( !$c->check_token($token) ) {
        $c->log->info('Invalid CSRF token');
        $c->detach('/error/http_403');
    }
}

no Moose;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
