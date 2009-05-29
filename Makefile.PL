use inc::Module::Install 0.90;

name 'Catalyst-Model-DBIC-Schema';
all_from 'lib/Catalyst/Model/DBIC/Schema.pm';

requires 'DBIx::Class'           => '0.08103';
requires 'Catalyst::Runtime'     => '5.80003';
requires 'MooseX::Traits'        => '0.05';
requires 'Moose';
requires 'Moose::Autobox';
requires 'MooseX::Types';
requires 'namespace::clean';
requires 'Carp::Clan';
requires 'List::MoreUtils';

test_requires 'Test::More';
test_requires 'Test::Exception';

feature 'Catalyst::Helper support',
    -default                      => 0,
    'Catalyst::Devel'             => '1.0',
    'Tie::IxHash'                 => 0,
    'DBIx::Class::Schema::Loader' => '0.04005';

feature 'Caching support',
    -default                      => 0,
    'DBIx::Class::Cursor::Cached' => 0;

feature 'Replication support',
    -default                   => 0,
    'MooseX::AttributeHelpers' => 0,
    'Hash::Merge'              => 0;

if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Catalyst/Model/DBIC/Schema.pm > README");
}

auto_provides;
auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Model-DBIC-Schema/';

WriteAll;
