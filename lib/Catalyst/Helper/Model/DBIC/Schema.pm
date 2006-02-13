package Catalyst::Helper::Model::DBIC::Schema;

use strict;
use warnings;
use Carp;

=head1 NAME

Catalyst::Helper::Model::DBIC::Schema - Helper for DBIC Schema Models

=head1 SYNOPSIS

    script/create.pl model Foo DBIC::Schema Foo::SchemaClass [ dsn user password ]

    Where:
      Foo is the short name for the Model class being generated
      Foo::SchemaClass is the fully qualified classname of your Schema,
        which isa DBIx::Class::Schema defined elsewhere.
      dsn, user, and password are optional if connection info is already
        defined in your Schema class (as it would be in the case of
        DBIx::Class::Schema::Loader).

=head1 DESCRIPTION

Helper for the DBIC Schema Models.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $schema_class, $dsn, $user, $pass ) = @_;

    $helper->{schema_class} = $schema_class || '';

    if(defined($dsn)) {
        $helper->{setup_connect_info} = 1;
        $helper->{dsn}         = $dsn  || '';
        $helper->{user}        = $user || '';
        $helper->{pass}        = $pass || '';
    }

    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Model::DBIC::Schema>,
L<Catalyst::Helper::Model::DBIC::SchemaLoader>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => '[% schema_class %]',
    [% IF setup_connect_info %]
    connect_info => [ '[% dsn %]',
                      '[% user %]',
                      '[% pass %]',
                      {
                          RaiseError         => 1,
                          PrintError         => 0,
                          ShowErrorStatement => 1,
                          TraceLevel         => 0,
                          AutoCommit         => 1,
                      }
                    ],
    [% END %]
);

=head1 NAME

[% class %] - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema
L<[% schema_class %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
