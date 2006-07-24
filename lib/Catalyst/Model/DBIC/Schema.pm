package Catalyst::Model::DBIC::Schema;

use strict;
use base qw/Catalyst::Model/;
use NEXT;
use UNIVERSAL::require;
use Carp;
use Data::Dumper;
require DBIx::Class;

our $VERSION = '0.17_01';

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

and a Role in MyApp/Schema/Role.pm:

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

  # You can access schema-level methods directly from the top-level model:
  $c->model('FilmDB')->source(...);
  $c->model('FilmDB')->resultset(...);
  $c->model('FilmDB')->class(...);
  $c->model('FilmDB')->any_other_schema_method(...);

  # For resultsets, there's an even quicker shortcut:
  $c->model('FilmDB::Actor')
  # is the same as $c->model('FilmDB')->resultset('Actor')

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

See L<DBIx::Class::Storage::DBI/connect_info> for more details.

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
L<DBIx::Class>).

=back

=head1 METHODS

=over 4

=item new

Instantiates the Model based on the above-documented ->config parameters.
The only required parameter is C<schema_class>.  C<connect_info> is
required in the case that C<schema_class> does not already have connection
information defined for it.

=item COMPONENT

Tells the Catalyst component architecture that the encapsulated schema
object is to be returned for $c->model calls for this model name.

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
        or croak "Cannot load schema_class '$schema_class': $@";

    my $schema_obj = $schema_class->clone;
    $schema_obj->storage_type($self->{storage_type}) if $self->{storage_type};
    $schema_obj->connection(@{$self->{connect_info}}) if $self->{connect_info};

    if(!$schema_obj->storage) {
        croak "Either ->config->{connect_info} must be defined for $class"
              . " or $schema_class must have connect info defined on it. "
              . "Here's what we got:\n"
              . Dumper($self);
    }

    $self->{schema_obj} = $schema_obj;

    no strict 'refs';
    foreach my $moniker ($self->schema->sources) {
        my $classname = "${class}::$moniker";
        # XXX -- Does this need to be dynamic, or can it be done w/ COMPONENT too?
        *{"${classname}::ACCEPT_CONTEXT"} = sub {
            shift;
            shift->model($model_name)->resultset($moniker);
        }
    }

    return $self;
}

sub COMPONENT { shift->{schema_obj} }

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
