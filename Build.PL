use strict;
use Module::Build;

my %arguments = (
    license            => 'perl',
    module_name        => 'Catalyst::Model::DBIC::Schema',
    requires           => {
        'DBIx::Class'           => 0.07000,
        'Catalyst'              => 5.7001,
        'UNIVERSAL::require'    => 0.10,
    },
    recommends         => {
        'Catalyst::Devel'             => 1.0,
        'DBIx::Class::Schema::Loader' => 0.03005,
    },
    build_requires     => {
        'Test::More'            => 0.32,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
);

Module::Build->new(%arguments)->create_build_script;
