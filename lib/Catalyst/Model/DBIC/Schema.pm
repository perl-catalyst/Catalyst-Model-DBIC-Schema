package Catalyst::Model::DBIC::Schema;

use Moose;
use mro 'c3';
extends 'Catalyst::Model';
with 'MooseX::Object::Pluggable';

our $VERSION = '0.24';

use Carp::Clan '^Catalyst::Model::DBIC::Schema::';
use Data::Dumper;
use DBIx::Class ();
use Scalar::Util 'reftype';
use MooseX::ClassAttribute;
use Moose::Autobox;

use Catalyst::Model::DBIC::Schema::Types qw/ConnectInfo SchemaClass/;

use namespace::clean -except => 'meta';

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
      connect_info => {
                        dsn => "DBI:...",
                        user => "username",
                        password => "password",
                      }
  );

See below for a full list of the possible config parameters.

=back

Now you have a working Model which accesses your separate DBIC Schema. This can
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

C<< $c->model('Schema::Source') >> returns a L<DBIx::Class::ResultSet> for 
the source name parameter passed. To find out more about which methods can 
be called on a ResultSet, or how to add your own methods to it, please see 
the ResultSet documentation in the L<DBIx::Class> distribution.

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

When your Catalyst app starts up, a thin Model layer is created as an 
interface to your DBIC Schema. It should be clearly noted that the model 
object returned by C<< $c->model('FilmDB') >> is NOT itself a DBIC schema or 
resultset object, but merely a wrapper proving L<methods|/METHODS> to access 
the underlying schema. 

In addition to this model class, a shortcut class is generated for each 
source in the schema, allowing easy and direct access to a resultset of the 
corresponding type. These generated classes are even thinner than the model 
class, providing no public methods but simply hooking into Catalyst's 
model() accessor via the 
L<ACCEPT_CONTEXT|Catalyst::Component/ACCEPT_CONTEXT> mechanism. The complete 
contents of each generated class is roughly equivalent to the following:

  package MyApp::Model::FilmDB::Actor
  sub ACCEPT_CONTEXT {
      my ($self, $c) = @_;
      $c->model('FilmDB')->resultset('Actor');
  }

In short, there are three techniques available for obtaining a DBIC 
resultset object: 

  # the long way
  my $rs = $c->model('FilmDB')->schema->resultset('Actor');

  # using the shortcut method on the model object
  my $rs = $c->model('FilmDB')->resultset('Actor');

  # using the generated class directly
  my $rs = $c->model('FilmDB::Actor');

In order to add methods to a DBIC resultset, you cannot simply add them to 
the source (row, table) definition class; you must define a separate custom 
resultset class. See L<DBIx::Class::Manual::Cookbook/"Predefined searches"> 
for more info.

=head1 CONFIG PARAMETERS

=head2 schema_class

This is the classname of your L<DBIx::Class::Schema> Schema.  It needs
to be findable in C<@INC>, but it does not need to be inside the 
C<Catalyst::Model::> namespace.  This parameter is required.

=head2 connect_info

This is an arrayref of connection parameters, which are specific to your
C<storage_type> (see your storage type documentation for more details). 
If you only need one parameter (e.g. the DSN), you can just pass a string 
instead of an arrayref.

This is not required if C<schema_class> already has connection information
defined inside itself (which isn't highly recommended, but can be done)

For L<DBIx::Class::Storage::DBI>, which is the only supported
C<storage_type> in L<DBIx::Class> at the time of this writing, the
parameters are your dsn, username, password, and connect options hashref.

See L<DBIx::Class::Storage::DBI/connect_info> for a detailed explanation
of the arguments supported.

Examples:

  connect_info => {
    dsn => 'dbi:Pg:dbname=mypgdb',
    user => 'postgres',
    password => ''
  }

  connect_info => {
    dsn => 'dbi:SQLite:dbname=foo.db',
    on_connect_do => [
      'PRAGMA synchronous = OFF',
    ]
  }

  connect_info => {
    dsn => 'dbi:Pg:dbname=mypgdb',
    user => 'postgres',
    password => '',
    pg_enable_utf8 => 1,
    on_connect_do => [
      'some SQL statement',
      'another SQL statement',
    ],
  }

Or using L<Config::General>:

    <Model::FilmDB>
        schema_class   MyApp::Schema::FilmDB
        roles Caching
        <connect_info>
            dsn   dbi:Pg:dbname=mypgdb
            user   postgres
            password ''
            auto_savepoint 1
            on_connect_do   some SQL statement
            on_connect_do   another SQL statement
        </connect_info>
    </Model::FilmDB>

or

    <Model::FilmDB>
        schema_class   MyApp::Schema::FilmDB
        connect_info   dbi:SQLite:dbname=foo.db
    </Model::FilmDB>

Or using L<YAML>:

  Model::MyDB:
      schema_class: MyDB
      connect_info:
          dsn: dbi:Oracle:mydb
          user: mtfnpy
          password: mypass
          LongReadLen: 1000000
          LongTruncOk: 1
          on_connect_do: [ "alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'" ]
          cursor_class: 'DBIx::Class::Cursor::Cached'

The old arrayref style with hashrefs for L<DBI> then L<DBIx::Class> options is also
supported:

  connect_info => [
    'dbi:Pg:dbname=mypgdb',
    'postgres',
    '',
    {
      pg_enable_utf8 => 1,
    },
    {
      auto_savepoint => 1,
      on_connect_do => [
        'some SQL statement',
        'another SQL statement',
      ],
    }
  ]

=head2 roles

Array of Roles to apply at BUILD time. Roles are relative to the
C<<MyApp::Model::DB::Role::> then C<<Catalyst::Model::DBIC::Schema::Role::>>
namespaces, unless prefixed with C<+> in which case they are taken to be a
fully qualified name. E.g.:

    roles Caching
    roles +MyApp::DB::Role::Foo

This is done using L<MooseX::Object::Pluggable>.

A new instance is created at application time, so any consumed required
attributes, coercions and modifiers will work.

Roles are applied before setup, schema and connection are set.

C<ref $self> will be an anon class if any roles are applied.

You cannot modify C<new> or C<BUILD>, modify C<setup> instead.

L</ACCEPT_CONTEXT> and L</finalize> can also be modified.

Roles that come with the distribution:

=over 4

=item L<Catalyst::Model::DBIC::Schema::Role::Caching>

=item L<Catalyst::Model::DBIC::Schema::Role::Replicated>

=back

=head2 storage_type

Allows the use of a different C<storage_type> than what is set in your
C<schema_class> (which in turn defaults to C<::DBI> if not set in current
L<DBIx::Class>).  Completely optional, and probably unnecessary for most
people until other storage backends become available for L<DBIx::Class>.

=head1 METHODS

=head2 new

Instantiates the Model based on the above-documented ->config parameters.
The only required parameter is C<schema_class>.  C<connect_info> is
required in the case that C<schema_class> does not already have connection
information defined for it.

=head2 schema

Accessor which returns the connected schema being used by the this model.
There are direct shortcuts on the model class itself for
schema->resultset, schema->source, and schema->class.

=head2 composed_schema

Accessor which returns the composed schema, which has no connection info,
which was used in constructing the C<schema> above.  Useful for creating
new connections based on the same schema/model.  There are direct shortcuts
from the model object for composed_schema->clone and composed_schema->connect

=head2 clone

Shortcut for ->composed_schema->clone

=head2 connect

Shortcut for ->composed_schema->connect

=head2 source

Shortcut for ->schema->source

=head2 class

Shortcut for ->schema->class

=head2 resultset

Shortcut for ->schema->resultset

=head2 storage

Provides an accessor for the connected schema's storage object.
Used often for debugging and controlling transactions.

=cut

class_has 'composed_schema' => (is => 'rw', isa => 'DBIx::Class::Schema');

has 'schema' => (is => 'rw', isa => 'DBIx::Class::Schema');

has 'schema_class' => (
    is => 'ro',
    isa => SchemaClass,
    coerce => 1,
    required => 1
);

has 'storage_type' => (is => 'rw', isa => 'Str');

has 'connect_info' => (is => 'ro', isa => ConnectInfo, coerce => 1);

# ref $self changes to anon after roles are applied, and _original_class_name is
# broken in MX::O::P 0.0009
has '_class_name' => (is => 'ro', isa => 'ClassName', default => sub {
    ref shift
});

has 'model_name' => (is => 'ro', isa => 'Str', default => sub {
    my $self = shift;

    my $class = ref $self;
    (my $model_name = $class) =~ s/^[\w:]+::(?:Model|M):://;

    $model_name
});

has 'roles' => (is => 'ro', isa => 'ArrayRef|Str');

sub BUILD {
    my $self = shift;
    my $class = ref $self;
    my $schema_class = $self->schema_class;

    if( !$self->connect_info ) {
        if($schema_class->storage && $schema_class->storage->connect_info) {
            $self->connect_info($schema_class->storage->connect_info);
        }
        else {
            die "Either ->config->{connect_info} must be defined for $class"
                  . " or $schema_class must have connect info defined on it."
		  . " Here's what we got:\n"
		  . Dumper($self);
        }
    }

    if (exists $self->connect_info->{cursor_class}) {
        eval { Class::MOP::load_class($self->connect_info->{cursor_class}) }
            or croak "invalid connect_info: Cannot load your cursor_class"
        . " ".$self->connect_info->{cursor_class}.": $@";
    }

    $self->_plugin_ns('Role');

    $self->load_plugins($self->roles->flatten) if $self->roles;

    $self->setup;

    $self->composed_schema($schema_class->compose_namespace($class));

    $self->schema($self->composed_schema->clone);

    $self->schema->storage_type($self->storage_type)
        if $self->storage_type;

    $self->schema->connection($self->connect_info);

    $self->_install_rs_models;

    $self->finalize;
}

sub clone { shift->composed_schema->clone(@_); }

sub connect { shift->composed_schema->connect(@_); }

sub storage { shift->schema->storage(@_); }

=head2 setup

Called at C<<BUILD>> time before configuration.

=cut

sub setup { 1 }

=head2 finalize

Called at the end of C<BUILD> after everything has been configured.

=cut

sub finalize { 1 }

=head2 ACCEPT_CONTEXT

Point of extension for doing things at C<<$c->model>> time, returns the model
instance, see L<Catalyst::Manual::Intro> for more information.

=cut

sub ACCEPT_CONTEXT { shift }

sub _install_rs_models {
    my $self  = shift;
    my $class = $self->_class_name;

    no strict 'refs';

    my @sources = $self->schema->sources;

    die "No sources found (did you forget to define your tables?)"
        unless @sources;

    foreach my $moniker (@sources) {
        my $classname = "${class}::$moniker";
        *{"${classname}::ACCEPT_CONTEXT"} = sub {
            shift;
            shift->model($self->model_name)->resultset($moniker);
        }
    }
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Helper::Model::DBIC::Schema>,
L<MooseX::Object::Pluggable>

Roles:

L<Catalyst::Model::DBIC::Schema::Role::Caching>,
L<Catalyst::Model::DBIC::Schema::Role::Replicated>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

Contributors:

Rafael Kitover, C<<rkitover at cpan.org>>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
