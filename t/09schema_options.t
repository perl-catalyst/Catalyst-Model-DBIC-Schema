use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;
use Catalyst::Model::DBIC::Schema;
use ASchemaClass;

plan tests => 4;

ok((my $m = instance(a_schema_option => 'mtfnpy')), 'instance');

is $m->schema->a_schema_option, 'mtfnpy', 'option was passed from config';

lives_ok { $m->a_schema_option('pass the crack pipe') } 'delegate called';

is $m->schema->a_schema_option, 'pass the crack pipe', 'delegation works';

sub instance {
    Catalyst::Model::DBIC::Schema->new({
        schema_class => 'ASchemaClass',
        connect_info => ['dbi:SQLite:foo.db', '', ''],
        @_,
    })
}
