use strict;
use Module::Build;

my %arguments = (
    license            => 'perl',
    module_name        => 'Catalyst::Model::DBIC::Schema',
    requires           => {
        'DBIx::Class'           => 0.05,
        'Catalyst'              => 5.64,
        'UNIVERSAL::require'    => 0,
        'Class::Data::Accessor' => 0,
        'Class::Accessor::Fast' => 0,
    },
    recommends         => {
        'DBIx::Class::Schema::Loader' => '0.01004',
    },
    build_requires     => {
        'Test::More'            => 0.32,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
);

Module::Build->new(%arguments)->create_build_script;
