use inc::Module::Install 0.65;

name 'Catalyst-Model-DBIC-Schema';
all_from 'lib/Catalyst/Model/DBIC/Schema.pm';

requires 'DBIx::Class'           => '0.07000';
requires 'Catalyst::Runtime'     => '5.70';
requires 'UNIVERSAL::require'    => '0.10';
requires 'Class::Data::Accessor' => '0.02';
requires 'Class::Accessor::Fast' => '0.22';
requires 'Test::More';

feature 'Catalyst::Helper support',
    -default                      => 0,
    'Catalyst::Devel'             => '1.0',
    'DBIx::Class::Schema::Loader' => '0.03006';

auto_install;
WriteAll;
