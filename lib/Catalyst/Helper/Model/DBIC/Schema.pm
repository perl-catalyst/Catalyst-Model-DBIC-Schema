package Catalyst::Helper::Model::DBIC::Schema;

use strict;

=head1 NAME

Catalyst::Helper::Model::DBIC::Schema - Helper for DBIC Schema Models

=head1 SYNOPSIS

    script/create.pl model Foo DBIC::Schema Foo::SchemaClass dsn user password

=head1 DESCRIPTION

Helper for the DBIC Plain Models.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $schemaclass, $dsn, $user, $pass ) = @_;
    $helper->{schemaclass} = $schemaclass || '';
    $helper->{dsn}         = $dsn  || '';
    $helper->{user}        = $user || '';
    $helper->{pass}        = $pass || '';
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

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
    schema_class => '[% schemaclass %]',
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
);

=head1 NAME

[% class %] - Catalyst DBIC Plain Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst::Model::DBIC::Schema Model

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
