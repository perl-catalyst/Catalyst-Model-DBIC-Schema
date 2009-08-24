package ASchemaClass;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_group_accessors(inherited => 'a_schema_option');

__PACKAGE__->load_classes;

1;
