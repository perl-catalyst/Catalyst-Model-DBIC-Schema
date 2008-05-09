package Catalyst::Model::DBIC::Schema;

use strict;
use warnings;

our $VERSION = '0.20';

use base qw/Catalyst::Model Class::Accessor::Fast Class::Data::Accessor/;
use NEXT;
use UNIVERSAL::require;
use Carp;
use Data::Dumper;
require DBIx::Class;

__PACKAGE__->mk_classaccessor('composed_schema');
__PACKAGE__->mk_accessors('schema');

=head1 NAME

Catalyst::Model::DBIC::Schema - DBIx::Class::Schema Model Class

=head1 SYNOPSIS

Manual creation of a DBIx::Class::Schema and a Catalyst::Model::DBIC::Schema:

=over

=item 1.

Create the DBIx:Class schema in MyApp/Schema/FilmDB.pm:

  package MyApp::Schema::FilmDB;
  use base qw/DBIx::Class::Schema/;

  __PACKAGE__->load_classes(qw/Actor Role/);

=item 2.

Create some classes for the tables in the database, for example an 
Actor in MyApp/Schema/FilmDB/Actor.pm:

  package MyApp::Schema::FilmDB::Actor;
  use base qw/DBIx::Class/

  __PACKAGE__->load_components(qw/Core/);
  __PACKAGE__->table('actor');

  ...

and a Role in MyApp/Schema/FilmDB/Role.pm:

  package MyApp::Schema::FilmDB::Role;
  use base qw/DBIx::Class/

  __PACKAGE__->load_components(qw/Core/);
  __PACKAGE__->table('role');

  ...    

Notice that the schema is in MyApp::Schema, not in MyApp::Model. This way it's 
usable as a standalone module and you can test/run it without Catalyst. 

=item 3.

To expose it to Catalyst as a model, you should create a DBIC Model in
MyApp/Model/FilmDB.pm:

  package MyApp::Model::FilmDB;
  use base qw/Catalyst::Model::DBIC::Schema/;

  __PACKAGE__->config(
      schema_class => 'MyApp::Schema::FilmDB',
      connect_info => [
                        "DBI:...",
                        "username",
                        "password",
                        {AutoCommit => 1}
                      ]
  );

See below for a full list of the possible config parameters.

=back

Now you have a working Model, accessing your separate DBIC Schema. Which can
be used/accessed in the normal Catalyst manner, via $c->model():

  my $actor = $c->model('FilmDB::Actor')->find(1);

You can also use it to set up DBIC authentication with 
Authentication::Store::DBIC in MyApp.pm:

  package MyApp;

  use Catalyst qw/... Authentication::Store::DBIC/;

  ...

  __PACKAGE__->config->{authentication}{dbic} = {
      user_class      => 'FilmDB::Actor',
      user_field      => 'name',
      password_field  => 'password'
  }

C<< $c->model() >> returns a L<DBIx::Class::ResultSet> for the source name
parameter passed. To find out more about which methods can be called on a
ResultSet, or how to add your own methods to it, please see the ResultSet
documentation in the L<DBIx::Class> distribution.

Some examples are given below:

  # to access schema methods directly:
  $c->model('FilmDB')->schema->source(...);

  # to access the source object, resultset, and class:
  $c->model('FilmDB')->source(...);
  $c->model('FilmDB')->resultset(...);
  $c->model('FilmDB')->class(...);

  # For resultsets, there's an even quicker shortcut:
  $c->model('FilmDB::Actor')
  # is the same as $c->model('FilmDB')->resultset('Actor')

  # To get the composed schema for making new connections:
  my $newconn = $c->model('FilmDB')->composed_schema->connect(...);

  # Or the same thing via a convenience shortcut:
  my $newconn = $c->model('FilmDB')->connect(...);

  # or, if your schema works on different storage drivers:
  my $newconn = $c->model('FilmDB')->composed_schema->clone();
  $newconn->storage_type('::LDAP');
  $newconn->connection(...);

  # and again, a convenience shortcut
  my $newconn = $c->model('FilmDB')->clone();
  $newconn->storage_type('::LDAP');
  $newconn->connection(...);

=head1 DESCRIPTION

This is a Catalyst Model for L<DBIx::Class::Schema>-based Models.  See
the documentation for L<Catalyst::Helper::Model::DBIC::Schema> for
information on generating these Models via Helper scripts.

=head1 CONFIG PARAMETERS

=over 4

=item schema_class

This is the classname of your L<DBIx::Class::Schema> Schema.  It needs
to be findable in C<@INC>, but it does not need to be inside the 
C<Catalyst::Model::> namespace.  This parameter is required.

=item connect_info

This is an arrayref of connection parameters, which are specific to your
C<storage_type> (see your storage type documentation for more details).

This is not required if C<schema_class> already has connection information
defined inside itself (which isn't highly recommended, but can be done)

For L<DBIx::Class::Storage::DBI>, which is the only supported
C<storage_type> in L<DBIx::Class> at the time of this writing, the
parameters are your dsn, username, password, and connect options hashref.

See L<DBIx::Class::Storage::DBI/connect_info> for a detailed explanation
of the arguments supported.

Examples:

  connect_info => [ 'dbi:Pg:dbname=mypgdb', 'postgres', '' ],

  connect_info => [
                    'dbi:SQLite:dbname=foo.db',
                    {
                      on_connect_do => [
                        'PRAGMA synchronous = OFF',
                      ],
                    }
                  ],

  connect_info => [
                    'dbi:Pg:dbname=mypgdb',
                    'postgres',
                    '',
                    { AutoCommit => 0 },
                    {
                      on_connect_do => [
                        'some SQL statement',
                        'another SQL statement',
                      ],
                    }
                  ],

=item storage_type

Allows the use of a different C<storage_type> than what is set in your
C<schema_class> (which in turn defaults to C<::DBI> if not set in current
L<DBIx::Class>).  Completely optional, and probably unnecessary for most
people until other storage backends become available for L<DBIx::Class>.

=back

=head1 METHODS

=over 4

=item new

Instantiates the Model based on the above-documented ->config parameters.
The only required parameter is C<schema_class>.  C<connect_info> is
required in the case that C<schema_class> does not already have connection
information defined for it.

=item schema

Accessor which returns the connected schema being used by the this model.
There are direct shortcuts on the model class itself for
schema->resultset, schema->source, and schema->class.

=item composed_schema

Accessor which returns the composed schema, which has no connection info,
which was used in constructing the C<schema> above.  Useful for creating
new connections based on the same schema/model.  There are direct shortcuts
from the model object for composed_schema->clone and composed_schema->connect

=item clone

Shortcut for ->composed_schema->clone

=item connect

Shortcut for ->composed_schema->connect

=item source

Shortcut for ->schema->source

=item class

Shortcut for ->schema->class

=item resultset

Shortcut for ->schema->resultset

=item storage

Provides an accessor for the connected schema's storage object.
Used often for debugging and controlling transactions.

=back

=cut

sub new {
    my $self = shift->NEXT::new(@_);
    
    my $class = ref($self);
    my $model_name = $class;
    $model_name =~ s/^[\w:]+::(?:Model|M):://;

    croak "->config->{schema_class} must be defined for this model"
        unless $self->{schema_class};

    my $schema_class = $self->{schema_class};

    $schema_class->require
        or croak "Cannot load schema class '$schema_class': $@";

    if( !$self->{connect_info} ) {
        if($schema_class->storage && $schema_class->storage->connect_info) {
            $self->{connect_info} = $schema_class->storage->connect_info;
        }
        else {
            croak "Either ->config->{connect_info} must be defined for $class"
                  . " or $schema_class must have connect info defined on it"
		  . "Here's what we got:\n"
		  . Dumper($self);
        }
    }

    $self->composed_schema($schema_class->compose_namespace($class));
    $self->schema($self->composed_schema->clone);

    $self->schema->storage_type($self->{storage_type})
        if $self->{storage_type};

    $self->schema->connection(@{$self->{connect_info}});
    
    no strict 'refs';
    foreach my $moniker ($self->schema->sources) {
        my $classname = "${class}::$moniker";
        *{"${classname}::ACCEPT_CONTEXT"} = sub {
            shift;
            shift->model($model_name)->resultset($moniker);
        }
    }

    return $self;
}

sub clone { shift->composed_schema->clone(@_); }

sub connect { shift->composed_schema->connect(@_); }

sub storage { shift->schema->storage(@_); }

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Helper::Model::DBIC::Schema>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
