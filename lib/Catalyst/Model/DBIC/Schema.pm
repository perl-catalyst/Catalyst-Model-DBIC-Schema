package Catalyst::Model::DBIC::Schema;

use strict;
use base qw/Catalyst::Model Class::Accessor::Fast Class::Data::Accessor/;
use NEXT;
use UNIVERSAL::require;
use Carp;
require DBIx::Class;

our $VERSION = '0.11';

__PACKAGE__->mk_classaccessor('composed_schema');
__PACKAGE__->mk_accessors('schema');

=head1 NAME

Catalyst::Model::DBIC::Schema - DBIx::Class::Schema Model Class

=head1 SYNOPSIS

    package MyApp::Model::Foo;
    use strict;
    use base 'Catalyst::Model::DBIC::Schema';

    __PACKAGE__->config(
        schema_class    => 'Foo::SchemaClass',
        connect_info    => [ 'dbi:Pg:dbname=foodb',
                             'postgres',
                             '',
                             { AutoCommit => 1 },
                             { limit_dialect => 'xxx',
                               quote_char => q{`},
                               name_sep => q{@},
                               on_connect_do => [
                                   'sql statement 1',
                                   'sql statement 2',
                               ]
                             }
                           ],
    );

    1;

    # In controller code:

    # ->schema To access schema methods:
    $c->model('Foo')->schema->source(...);

    # certain ->schema methods (source, resultset, class) have shortcuts
    $c->model('Foo')->source(...);
    $c->model('Foo')->resultset(...);
    $c->model('Foo')->class(...);

    # For resultsets, there's an even quicker shortcut:
    $c->model('Foo::Bar')
    # is the same as $c->model('Foo')->resultset('Bar')

    # To get the composed schema for making new connections:
    my $newconn = $c->model('Foo')->composed_schema->connect(...);

    # Or the same thing via a convenience shortcut:
    my $newconn = $c->model('Foo')->connect(...);

    # or, if your schema works on different storage drivers:
    my $newconn = $c->model('Foo')->composed_schema->clone();
    $newconn->storage_type('::LDAP');
    $newconn->connection(...);

    # and again, a convenience shortcut
    my $newconn = $c->model('Foo')->clone();
    $newconn->storage_type('::LDAP');
    $newconn->connection(...);

=head1 DESCRIPTION

This is a Catalyst Model for L<DBIx::Class::Schema>-based Models.  See
the documentation for L<Catalyst::Helper::Model::DBIC::Schema> and
L<Catalyst::Helper::Model::DBIC::SchemaLoader> for information
on generating these Models via Helper scripts.  The latter of the two
will also generated a L<DBIx::Class::Schema::Loader>-based Schema class
for you.

=head1 CONFIG PARAMETERS

=over 4

=item schema_class

This is the classname of your L<DBIx::Class::Schema> Schema.  It needs
to be findable in C<@INC>, but it does not need to be underneath
C<Catalyst::Model::>.  This parameter is required.

=item connect_info

This is an arrayref of connection parameters, which are specific to your
C<storage_type> (see your storage type documentation for more details).

This is not required if C<schema_class> already has connection information
defined in itself (which would be the case for a Schema defined by
L<DBIx::Class::Schema::Loader>, for instance).

For L<DBIx::Class::Storage::DBI>, which is the only supported
C<storage_type> in L<DBIx::Class> at the time of this writing, the
parameters are your dsn, username, password, and connect options hashref.

If you need to specify the L<DBIx::Class::Storage::DBI> specific parameter
C<on_connect_do>, or the related C<sql_maker> options C<limit_dialect>,
C<quote_char>, or C<name_sep>, you can place these options into a hashref
as the final element of the C<connect_info> arrayref.  If in doubt, don't
specify these options.  You would know it if you needed them.

Examples:

    connect_info => [ 'dbi:Pg:dbname=mypgdb', 'postgres', '' ],
    connect_info => [
                      'dbi:SQLite:dbname=foo.db',
                      {
                        on_connect_do => [
                          'some SQL statement',
                          'another SQL statement',
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
There are already direct shortcuts on the model class itself for
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
                  . " or $schema_class must have connect info defined on it";
        }
    }

    $self->composed_schema($schema_class->compose_namespace($class));
    $self->schema($self->composed_schema->clone);

    $self->schema->storage_type($self->{storage_type})
        if $self->{storage_type};

    # XXX This is temporary, until DBIx::Class::Storage::DBI supports the
    #  same syntax and we switch our requisite to that version somewhere
    #  down the line.  This syntax is already committed into DBIx::Class
    #  dev branch post-0.06.
    # At that time, this whole block can revert back to just being:
    #  $self->schema->connection(@{$self->{connect_info}});
    
    my $connect_info = [ @{$self->{connect_info}} ];
    my ($on_connect_do, %sql_maker_opts);
    if($DBIx::Class::VERSION < 0.069) {
        my $used;
        my $last_info = $self->{connect_info}->[-1];
        if(ref $last_info eq 'HASH') {
            if($on_connect_do = $last_info->{on_connect_do}) {
              $used = 1;
            }
            for my $sql_maker_opt (qw/limit_dialect quote_char name_sep/) {
              if(my $opt_val = $last_info->{$sql_maker_opt}) {
                $used = 1;
                $sql_maker_opts{$sql_maker_opt} = $opt_val;
              }
            }
            pop(@$connect_info) if $used;
        }
    }

    $self->schema->connection(@$connect_info);

    if($DBIx::Class::VERSION < 0.069) {
        $self->schema->storage->on_connect_do($on_connect_do)
            if $on_connect_do;
        foreach my $sql_maker_opt (keys %sql_maker_opts) {
            $self->schema->storage->sql_maker->$sql_maker_opt(
                $sql_maker_opts{$sql_maker_opt}
            );
        }
    }

    # XXX end of compatibility block referenced above

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
L<DBIx::Class::Schema::Loader>, L<Catalyst::Helper::Model::DBIC::Schema>,
L<Catalyst::Helper::Model::DBIC::SchemaLoader>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
