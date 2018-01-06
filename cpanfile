requires "Archive::Tar" => "0";
requires "Catalyst::Action::RenderView" => "0";
requires "Catalyst::Authentication::Credential::HTTP" => "0";
requires "Catalyst::Authentication::Store::DBIx::Class" => "0";
requires "Catalyst::Plugin::ConfigLoader" => "0";
requires "Catalyst::Plugin::Session" => "0";
requires "Catalyst::Plugin::Session::State::Cookie" => "0";
requires "Catalyst::Plugin::Session::Store::DBI" => "0";
requires "Catalyst::Plugin::StackTrace" => "0";
requires "Catalyst::Plugin::Static::Simple" => "0";
requires "Catalyst::Runtime" => "5.9";
requires "Catalyst::View::CSV" => "1.7";
requires "Catalyst::View::JSON" => "0";
requires "Catalyst::View::TT" => "0";
requires "Class::Load" => "0";
requires "Config::General" => "0";
requires "Config::ZOMG" => "1.0";
requires "Crypt::Eksblowfish::Bcrypt" => "0";
requires "DBD::SQLite" => "0";
requires "DBI" => "0";
requires "DBIx::Class" => "0";
requires "DBIx::Class::EncodedColumn" => "0";
requires "DBIx::Class::Helpers" => "0";
requires "DBIx::Class::Tree" => "0";
requires "DateTime::Format::RFC3339" => "0";
requires "Digest::SHA1" => "0";
requires "HTML::FormHandler" => "0";
requires "HTML::FormHandler::Model::DBIC" => "0";
requires "Log::Log4perl" => "1.46";
requires "Module::Runtime" => "0";
requires "Moose" => "0";
requires "MooseX::Daemonize" => "0";
requires "MooseX::Getopt" => "0";
requires "MooseX::Storage" => "0";
requires "MooseX::Workers" => "0";
requires "Net::NBName" => "0";
requires "Net::OpenSSH" => "0";
requires "Net::SNMP" => "0";
requires "POE" => "0";
requires "Plack::Middleware::ReverseProxy" => "0";
requires "Regexp::Common" => "0";
requires "SQL::Translator" => "0";
requires "Text::CSV" => "0";
requires "YAML::Syck" => "0";
requires "namespace::autoclean" => "0";
recommends "Net::Pcap" => "0";
recommends "NetPacket" => "0";
recommends "SNMP::Info" => "3.27";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::WWW::Mechanize::Catalyst" => "0.60";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
};

on 'develop' => sub {
  requires "Catalyst::Devel" => "0";
  requires "Dist::Zilla" => "0";
  requires "Git::Wrapper" => "0";
  requires "Perl::Tidy" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Version" => "1";
  requires "Test::Deep" => "0";
};

# used for heroku like environmens

feature 'sqlite', 'SQLite support' => sub {
   requires 'DBD::SQLite';
};

feature 'mysql', 'MySQL support' => sub {
   requires 'DBD::mysql';
};

feature 'postgres', 'PostgreSQL support' => sub {
   requires 'DBD::Pg';
}
