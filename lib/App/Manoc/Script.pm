package App::Manoc::Script;
use Moose;

##VERSION

with 'MooseX::Getopt::Dashes';
with 'App::Manoc::Logger::Role';
with 'App::Manoc::Script::ConfigRole';

use App::Manoc::DB;
use App::Manoc::Logger;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0
);

has 'debug' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0
);

has 'schema' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_schema'
);

sub _build_schema {
    my $self = shift;

    my $config       = $self->config;
    my $connect_info = $config->{'Model::ManocDB'}->{connect_info};

    my $schema = App::Manoc::DB->connect($connect_info);

    return $schema;
}

sub _init_logging {
    my $self = shift;

    return if App::Manoc::Logger->initialized();

    my %args;
    $args{debug} = $self->debug;
    $args{class} = ref($self);

    App::Manoc::Logger->init( \%args );
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
