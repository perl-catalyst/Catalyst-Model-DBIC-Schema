package Catalyst::Helper::Model::DBIC::Schema;

use strict;
use warnings;
use Carp;

=head1 NAME

Catalyst::Helper::Model::DBIC::Schema - Helper for DBIC Schema Models

=head1 SYNOPSIS

  script/create.pl model Foo DBIC::Schema Foo::SchemaClass [ connect_info arguments ]

  Where:
    Foo is the short name for the Model class being generated
    Foo::SchemaClass is the fully qualified classname of your Schema,
      which isa DBIx::Class::Schema defined elsewhere.
    connect_info arguments are the same as what DBIx::Class::Schema::connect
      expects, and are storage_type-specific.  For DBI-based storage, these
      arguments are the dsn, username, password, and connect options,
      respectively.

=head1 TYPICAL EXAMPLES

  script/myapp_create.pl model Foo DBIC::Schema FooSchema dbi:mysql:foodb myuname mypass '{ AutoCommit => 1 }'

  # -or, if the schema already has connection info and you want to re-use that:
  script/myapp_create.pl model Foo DBIC::Schema FooSchema

=head1 DESCRIPTION

Helper for the DBIC Schema Models.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $schema_class, @connect_info) = @_;

    $helper->{schema_class} = $schema_class || '';

    if(@connect_info) {
        $helper->{setup_connect_info} = 1;
        for(@connect_info) {
            $_ = qq{'$_'} if $_ !~ /^\s*[[{]/;
        }
        $helper->{connect_info} = \@connect_info;
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

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => '[% schema_class %]',
    [% IF setup_connect_info %]connect_info => [
        [% FOREACH arg = connect_info %][% arg %],
        [% END %]
    ],[% END %]
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
