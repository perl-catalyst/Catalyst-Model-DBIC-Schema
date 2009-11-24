use inc::Module::Install 0.91;

name 'Catalyst-Model-DBIC-Schema';
all_from 'lib/Catalyst/Model/DBIC/Schema.pm';

requires 'DBIx::Class'           => '0.08114';
requires 'Catalyst::Runtime'     => '5.80005';
requires 'CatalystX::Component::Traits' => '0.10';

requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::autoclean';
requires 'Carp::Clan';
requires 'List::MoreUtils';
requires 'Tie::IxHash';

test_requires 'Test::More';
test_requires 'Test::Exception';

feature 'Catalyst::Helper support',
    -default                      => 0,
    'Catalyst::Devel'             => '1.0',
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

clean_files 'README';

auto_provides;
auto_install;
resources repository =>
    'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Model-DBIC-Schema/';

WriteAll;
