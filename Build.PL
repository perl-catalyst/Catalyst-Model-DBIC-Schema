use strict;
use Module::Build;

my %arguments = (
    license            => 'perl',
    module_name        => 'Catalyst::Model::DBIC::Schema',
    requires           => {
        'DBIx::Class'           => 0.06,
        'Catalyst'              => 5.64,
        'UNIVERSAL::require'    => 0.10,
        'Class::Data::Accessor' => 0.02,
        'Class::Accessor::Fast' => 0.22,
    },
    recommends         => {
        'DBIx::Class::Schema::Loader' => '0.03',
    },
    build_requires     => {
        'Test::More'            => 0.32,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
);

Module::Build->new(%arguments)->create_build_script;
