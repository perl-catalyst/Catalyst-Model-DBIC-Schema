use inc::Module::Install 0.65;

name 'Catalyst-Model-DBIC-Schema';
all_from 'lib/Catalyst/Model/DBIC/Schema.pm';

requires 'DBIx::Class'           => '0.08101';
requires 'DBIx::Class::Cursor::Cached';
requires 'Catalyst::Runtime'     => '5.70';
requires 'UNIVERSAL::require'    => '0.10';
requires 'Class::Data::Accessor' => '0.02';
requires 'Class::Accessor::Fast' => '0.22';

requires 'parent';
requires 'MRO::Compat';
requires 'namespace::clean';

if($] < 5.009_005) {
    requires 'Class::C3::XS' => '0.08';
    requires 'Class::C3' => '0.20';
}

test_requires 'Test::More';

feature 'Catalyst::Helper support',
    -default                      => 0,
    'Catalyst::Devel'             => '1.0',
    'Tie::IxHash'                 => 0,
    'DBIx::Class::Schema::Loader' => '0.04005';

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Model/DBIC/Schema.pm > README");
}

auto_provides;
auto_install;
WriteAll;
