package Catalyst::Model::DBIC::Schema;

use Moose;
use mro 'c3';
extends 'Catalyst::Model';
with 'CatalystX::Component::Traits';

our $VERSION = '0.27';
$VERSION = eval $VERSION;

use namespace::autoclean;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use Data::Dumper;
use DBIx::Class ();

use Catalyst::Model::DBIC::Schema::Types
    qw/ConnectInfo LoadedClass/;

use MooseX::Types::Moose qw/ArrayRef Str ClassName Undef/;

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
L<Catalyst::Authentication::Store::DBIx::Class> in MyApp.pm:

  package MyApp;

  use Catalyst qw/... Authentication .../;

  ...

  __PACKAGE__->config->{authentication} = 
                {  
                    default_realm => 'members',
                    realms => {
                        members => {
                            credential => {
                                class => 'Password',
                                password_field => 'password',
                                password_type => 'hashed'
                                password_hash_type => 'SHA-256'
                            },
                            store => {
                                class => 'DBIx::Class',
                                user_model => 'DB::User',
                                role_relation => 'roles',
                                role_field => 'rolename',                   
                            }
                        }
                    }
                };

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

Any options in your config not listed here are passed to your schema.

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
        traits Caching
        <connect_info>
            dsn   dbi:Pg:dbname=mypgdb
            user   postgres
            password ""
            auto_savepoint 1
	    quote_char """
            on_connect_do   some SQL statement
            on_connect_do   another SQL statement
        </connect_info>
        user_defined_schema_accessor foo
    </Model::FilmDB>

or

    <Model::FilmDB>
        schema_class   MyApp::Schema::FilmDB
        connect_info   dbi:SQLite:dbname=foo.db
    </Model::FilmDB>

Or using L<YAML>:

  Model::MyDB:
      schema_class: MyDB
      traits: Caching
      connect_info:
          dsn: dbi:Oracle:mydb
          user: mtfnpy
          password: mypass
          LongReadLen: 1000000
          LongTruncOk: 1
          on_connect_call: 'datetime_setup'
	  quote_char: '"'

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

=head2 traits

Array of Traits to apply to the instance. Traits are L<Moose::Role>s.

They are relative to the C<< MyApp::TraitFor::Model::DBIC::Schema:: >>, then the C<<
Catalyst::TraitFor::Model::DBIC::Schema:: >> namespaces, unless prefixed with C<+>
in which case they are taken to be a fully qualified name. E.g.:

    traits Caching
    traits +MyApp::TraitFor::Model::Foo

A new instance is created at application time, so any consumed required
attributes, coercions and modifiers will work.

Traits are applied at L<Catalyst::Component/COMPONENT> time using
L<CatalystX::Component::Traits>.

C<ref $self> will be an anon class if any traits are applied, C<<
$self->_original_class_name >> will be the original class.

When writing a Trait, interesting points to modify are C<BUILD>, L</setup> and
L</ACCEPT_CONTEXT>.

Traits that come with the distribution:

=over 4

=item L<Catalyst::TraitFor::Model::DBIC::Schema::Caching>

=item L<Catalyst::TraitFor::Model::DBIC::Schema::Replicated>

=back

=head2 storage_type

Allows the use of a different C<storage_type> than what is set in your
C<schema_class> (which in turn defaults to C<::DBI> if not set in current
L<DBIx::Class>).  Completely optional, and probably unnecessary for most
people until other storage backends become available for L<DBIx::Class>.

=head1 ATTRIBUTES

The keys you pass in the model configuration are available as attributes.

Other attributes available:

=head2 connect_info

Your connect_info args normalized to hashref form (with dsn/user/password.) See
L<DBIx::Class::Storage::DBI/connect_info> for more info on the hashref form of
L</connect_info>.

=head2 model_name

The model name L<Catalyst> uses to resolve this model, the part after
C<::Model::> or C<::M::> in your class name. E.g. if your class name is
C<MyApp::Model::DB> the L</model_name> will be C<DB>.

=head2 _default_cursor_class

What to reset your L<DBIx::Class::Storage::DBI/cursor_class> to if a custom one
doesn't work out. Defaults to L<DBIx::Class::Storage::DBI::Cursor>.

=head1 ATTRIBUTES FROM L<MooseX::Traits::Pluggable>

=head2 _original_class_name

The class name of your model before any L</traits> are applied. E.g.
C<MyApp::Model::DB>.

=head2 _traits

Unresolved arrayref of traits passed in the config.

=head2 _resolved_traits

Traits you used resolved to full class names.

=head1 METHODS

Methods not listed here are delegated to the connected schema used by the model
instance, so the following are equivalent:

    $c->model('DB')->schema->my_accessor('foo');
    # or
    $c->model('DB')->my_accessor('foo');

Methods on the model take precedence over schema methods.

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

has schema_class => (
    is => 'ro',
    isa => LoadedClass,
    coerce => 1,
    required => 1
);

has storage_type => (is => 'rw', isa => Str);

has connect_info => (is => 'rw', isa => ConnectInfo, coerce => 1);

has model_name => (
    is => 'ro',
    isa => Str,
    required => 1,
    lazy_build => 1,
);

has _default_cursor_class => (
    is => 'ro',
    isa => LoadedClass,
    default => 'DBIx::Class::Storage::DBI::Cursor',
    coerce => 1
);

sub BUILD {
    my ($self, $args) = @_;
    my $class = $self->_original_class_name;
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

    $self->setup;

    $self->composed_schema($schema_class->compose_namespace($class));

    $self->meta->make_mutable;
    $self->meta->add_attribute('schema',
        is => 'rw',
        isa => 'DBIx::Class::Schema',
        handles => $self->_delegates
    );
    $self->meta->make_immutable;

    $self->schema($self->composed_schema->clone);

    $self->_pass_options_to_schema($args);

    $self->schema->storage_type($self->storage_type)
        if $self->storage_type;

    $self->schema->connection($self->connect_info);

    $self->_install_rs_models;
}

sub clone { shift->composed_schema->clone(@_); }

sub connect { shift->composed_schema->connect(@_); }

=head2 setup

Called at C<BUILD> time before configuration, but after L</connect_info> is
set. To do something after configuuration use C<< after BUILD => >>.

=cut

sub setup { 1 }

=head2 ACCEPT_CONTEXT

Point of extension for doing things at C<< $c->model >> time with context,
returns the model instance, see L<Catalyst::Manual::Intro/ACCEPT_CONTEXT> for
more information.

=cut

sub ACCEPT_CONTEXT { shift }

sub _install_rs_models {
    my $self  = shift;
    my $class = $self->_original_class_name;

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

sub _reset_cursor_class {
    my $self = shift;

    if ($self->storage->can('cursor_class')) {
	$self->storage->cursor_class($self->_default_cursor_class)
	    if $self->storage->cursor_class ne $self->_default_cursor_class;
    }
}

{
    my %COMPOSED_CACHE;

    sub composed_schema {
	my $self = shift;
	my $class = $self->_original_class_name;
	my $store = \$COMPOSED_CACHE{$class}{$self->schema_class};

	$$store = shift if @_;

	return $$store
    }
}

sub _build_model_name {
    my $self  = shift;
    my $class = $self->_original_class_name;
    (my $model_name = $class) =~ s/^[\w:]+::(?:Model|M):://;

    return $model_name;
}

sub _delegates {
    my $self = shift;

    my $schema_meta = Class::MOP::Class->initialize($self->schema_class);
    my @schema_methods = $schema_meta->get_all_method_names;

# combine with any already added by other schemas
    my @handles = eval {
        @{ $self->meta->find_attribute_by_name('schema')->handles }
    };

# now kill the attribute, otherwise add_attribute in BUILD will not do the right
# thing (it clears the handles for some reason.) May be a Moose bug.
    eval { $self->meta->remove_attribute('schema') };

    my %schema_methods;
    @schema_methods{ @schema_methods, @handles } = ();
    @schema_methods = keys %schema_methods;

    my @my_methods = $self->meta->get_all_method_names;
    my %my_methods;
    @my_methods{@my_methods} = ();

    my @delegates;
    for my $method (@schema_methods) {
        push @delegates, $method unless exists $my_methods{$method};
    }

    return \@delegates;
}

sub _pass_options_to_schema {
    my ($self, $args) = @_;

    my @attributes = map {
        $_->init_arg || ()
    } $self->meta->get_all_attributes;

    my %attributes;
    @attributes{@attributes} = ();

    for my $opt (keys %$args) {
        if (not exists $attributes{$opt}) {
            next unless $self->schema->can($opt);
            $self->schema->$opt($self->{$opt});
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
L<CatalystX::Component::Traits>, L<MooseX::Traits::Pluggable>

Traits:

L<Catalyst::TraitFor::Model::DBIC::Schema::Caching>,
L<Catalyst::TraitFor::Model::DBIC::Schema::Replicated>

=head1 AUTHOR

Brandon L Black C<blblack at gmail.com>

=head1 CONTRIBUTORS

caelum: Rafael Kitover C<rkitover at cpan.org>

Dan Dascalescu C<dandv at cpan.org>

=head1 COPYRIGHT

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
# vim:sts=4 sw=4 et:
