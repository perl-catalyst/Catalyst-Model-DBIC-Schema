package Catalyst::Helper::Model::DBIC::Schema;

use strict;
use warnings;
use Carp;
use UNIVERSAL::require;

=head1 NAME

Catalyst::Helper::Model::DBIC::Schema - Helper for DBIC Schema Models

=head1 SYNOPSIS

  script/create.pl model ModelName DBIC::Schema My::SchemaClass [ create=dynamic | create=static ] [ connect_info arguments ]

=head1 DESCRIPTION

Helper for the DBIC Schema Models.

=head2 Arguments:

    ModelName is the short name for the Model class being generated

    My::SchemaClass is the fully qualified classname of your Schema,
      which might or might not yet exist.

    create=dynamic instructs this Helper to generate the named Schema
      class for you, basing it on L<DBIx::Class::Schema::Loader> (which
      means the table information will always be dynamically loaded at
      runtime from the database).

    create=static instructs this Helper to generate the named Schema
      class for you, using L<DBIx::Class::Schema::Loader> in "one shot"
      mode to create a standard, manually-defined L<DBIx::Class::Schema>
      setup, based on what the Loader sees in your database at this moment.
      A Schema/Model pair generated this way will not require
      L<DBIx::Class::Schema::Loader> at runtime, and will not automatically
      adapt itself to changes in your database structure.  You can edit
      the generated classes by hand to refine them.

    connect_info arguments are the same as what DBIx::Class::Schema::connect
      expects, and are storage_type-specific.  For DBI-based storage, these
      arguments are the dsn, username, password, and connect options,
      respectively.  These are optional for existing Schemas, but required
      if you use either of the C<create=> options.

Use of either of the C<create=> options requires L<DBIx::Class::Schema::Loader>.

=head1 TYPICAL EXAMPLES

  # Use DBIx::Class::Schema::Loader to create a static DBIx::Class::Schema,
  #  and a Model which references it:
  script/myapp_create.pl model ModelName DBIC::Schema My::SchemaClass create=static dbi:mysql:foodb myuname mypass

  # Create a dynamic DBIx::Class::Schema::Loader-based Schema,
  #  and a Model which references it:
  script/myapp_create.pl model ModelName DBIC::Schema My::SchemaClass create=dynamic dbi:mysql:foodb myuname mypass

  # Reference an existing Schema of any kind, and provide some connection information for ->config:
  script/myapp_create.pl model ModelName DBIC::Schema My::SchemaClass dbi:mysql:foodb myuname mypass

  # Same, but don't supply connect information yet (you'll need to do this
  #  in your app config, or [not recommended] in the schema itself).
  script/myapp_create.pl model ModelName DBIC::Schema My::SchemaClass

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $schema_class, @connect_info) = @_;

    $helper->{schema_class} = $schema_class
        or die "Must supply schema class name";

    my $create = '';
    if($connect_info[0] && $connect_info[0] =~ /^create=(dynamic|static)$/) {
        $create = $1;
        shift @connect_info;
    }

    if(@connect_info) {
        $helper->{setup_connect_info} = 1;
        for(@connect_info) {
            $_ = qq{'$_'} if $_ !~ /^\s*[[{]/;
        }
        $helper->{connect_info} = \@connect_info;
    }

    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );

    if($create eq 'dynamic') {
        my @schema_parts = split(/\:\:/, $helper->{schema_class});
        my $schema_file_part = pop @schema_parts;

        my $schema_dir  = File::Spec->catfile( $helper->{base}, 'lib', @schema_parts );
        my $schema_file = File::Spec->catfile( $schema_dir, $schema_file_part . '.pm' );

        $helper->mk_dir($schema_dir);
        $helper->render_file( 'schemaclass', $schema_file );
    }
    elsif($create eq 'static') {
       my $schema_dir  = File::Spec->catfile( $helper->{base}, 'lib' );
       DBIx::Class::Schema::Loader->use("dump_to_dir:$schema_dir", 'make_schema_at')
           or die "Cannot load DBIx::Class::Schema::Loader: $@";
       make_schema_at(
           $schema_class,
           { relationships => 1 },
           \@connect_info,
       );
    }
}

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Model::DBIC::Schema>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__schemaclass__
package [% schema_class %];

use strict;
use base qw/DBIx::Class::Schema::Loader/;

__PACKAGE__->loader_options(
    relationships => 1,
    # debug => 1,
);

=head1 NAME

[% schema_class %] - DBIx::Class::Schema::Loader class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Generated by L<Catalyst::Model::DBIC::Schema> for use in L<[% class %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

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

L<Catalyst::Model::DBIC::Schema> Model using schema L<[% schema_class %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
