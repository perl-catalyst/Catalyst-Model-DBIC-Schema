package Catalyst::Model::DBIC::Schema;

use strict;
use base qw/Catalyst::Base Class::Accessor::Fast Class::Data::Accessor/;
use NEXT;
use UNIVERSAL::require;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('composed_schema');
__PACKAGE__->mk_accessors('schema');

=head1 NAME

Catalyst::Model::DBIC::Schema - DBIx::Class::Schema Model Class

=head1 SYNOPSIS

    package MyApp::Model::Foo;
    use strict;
    use base 'Catalyst::Model::DBIC::Schema';

    __PACKAGE__->config(
        schema_class => 'Foo::SchemaClass',
        connect_info => [ 'dbi:Pg:dbname=foodb',
                          'postgres',
                          '',
                          { AutoCommit => 1 },
                        ],
    );

    1;

    # In controller code:

    # ->schema To access schema methods:
    $c->model('Foo')->schema->source(...);

    # Shortcut to the schema resultset monikers for ->search et al:
    $c->model('Foo::Bar')->search(...);
    # is the same as $c->model('Foo')->schema->resultset('Bar')->search(...);

    # To get the composed schema for making new connections:
    my $newconn = $c->model('Foo')->composed_schema->connect(...);

    # Or the same thing via a convenience shortcut:
    my $newconn = $c->model('Foo')->connect(...);

    # or, if your schema works on different storage drivers:
    my $newconn = $c->model('Foo')->composed_schema->clone();
    $newconn->storage_type('::LDAP');
    $newconn->connect(...);

    # and again, a convenience shortcut
    my $newconn = $c->model('Foo')->clone();
    $newconn->storage_type('::LDAP');
    $newconn->connect(...);

=head1 DESCRIPTION

This is a Catalyst Model for L<DBIx::Class::Schema>-based Models.

=head1 CONFIG PARAMETERS

=over 4

=item schema_class

This is the classname of your L<DBIx::Class::Schema> Schema.  It needs
to be findable in C<@INC>, but it does not need to be underneath
C<Catalyst::Model::>.

=item connect_info

This is an arrayref of connection parameters, which are specific to your
C<storage_type>.  For C<::DBI>, which is the only supported C<storage_type>
in L<DBIx::Class> at the time of this writing, the 4 parameters are your
dsn, username, password, and connect options hashref.

=item storage_type

Allows the use of a different C<storage_type> than what is set in your
C<schema_class> (which in turn defaults to C<::DBI> if not set in current
L<DBIx::Class>).  Completely optional, and probably unneccesary for most
people, until other storage backends become available for L<DBIx::Class>.

=back

=head1 METHODS

=over 4

=item new

Instantiates the Model based on the above-documented ->config parameters.

=item schema

Accessor which returns the connected schema being used by the this model.

=item composed_schema

Accessor which returns the composed schema, which has no connection info,
which was used in constructing the C<schema> above.  Useful for creating
new connections based on the same schema/model.

=item clone

Shortcut for ->composed_schema->clone

=item connect

Shortcut for ->composed_schema->connect

=back

=cut

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new($c);
    
    my $class = ref($self);
    my $model_name = $class;
    $model_name =~ s/^[\w:]+::(?:Model|M):://;

    foreach (qw/ connect_info schema_class /) {
        croak "->config->{$_} must be defined for this model"
            unless $self->{$_};
    }

    my $schema_class = $self->{schema_class};

    $schema_class->require
        or croak "Cannot load schema class '$schema_class': $@";

    $self->composed_schema($schema_class->compose_namespace($class));
    $self->schema($self->composed_schema->clone);
    $self->schema->storage_type($self->{storage_type}) if $self->{storage_type};
    $self->schema->connect(@{$self->{connect_info}});

    no strict 'refs';
    foreach my $moniker ($self->schema->sources) {
        *{"${class}::${moniker}::ACCEPT_CONTEXT"} = sub {
            shift;
            shift->model($model_name)->schema->resultset($moniker);
        }
    }

    return $self;
}

# convenience method
sub clone { shift->composed_schema->clone(@_); }

# convenience method
sub connect { shift->composed_schema->connect(@_); }

=head1 SEE ALSO

L<Catalyst>, L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
