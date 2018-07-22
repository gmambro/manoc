package App::Manoc::Script::ConfigRole;
use Moose::Role;

##VERSION

use Config::ZOMG;
use Cwd;
use FindBin;
use File::Spec::Functions;

has 'config' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_config'
);

has 'manoc_config_dir' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    default => sub { catdir( $FindBin::Bin, updir() ) }
);

sub _build_config {
    my $self = shift;
    my $config;

    if ( $ENV{APP_MANOC_CONF} ) {
        $config = Config::ZOMG->open( file => $ENV{APP_MANOC_CONFIG}, );
        my $path = catdir( $ENV{APP_MANOC_CONFIG}, updir() );
        $self->manoc_config_dir($path);
    }
    else {
        my @config_paths = ( catdir( $FindBin::Bin, updir() ), '/etc/manoc', );

        foreach my $path (@config_paths) {
            $config = Config::ZOMG->open( path => $path, name => 'manoc', ) ||
                Config::ZOMG->open( path => $path, name => 'app_manoc' );

            if ($config) {
                $self->manoc_config_dir($path);
                last;
            }
        }
    }
    if ( !$config ) {
        $config = {
            name             => 'Manoc',
            'Model::ManocDB' => $App::Manoc::DB::DEFAULT_CONFIG,
        };
        $self->manoc_config_dir( getcwd() );
    }

    return $config;
}

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
