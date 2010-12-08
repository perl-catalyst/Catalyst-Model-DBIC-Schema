package AnotherSchemaClass::Result::Users;

# empty schemas no longer work

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("users");

1;
