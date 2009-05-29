package Catalyst::Model::DBIC::Schema::Trait::Replicated;

use Moose::Role;
use Moose::Autobox;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';

use Catalyst::Model::DBIC::Schema::Types 'ConnectInfos';

use namespace::clean -except => 'meta';

=head1 NAME

Catalyst::Model::DBIC::Schema::Trait::Replicated - Replicated storage support for
L<Catalyst::Model::DBIC::Schema>

=head1 SYNOPSiS

    __PACKAGE__->config({
        traits => ['Replicated']
        connect_info => 
            ['dbi:mysql:master', 'user', 'pass'],
        replicants => [
            ['dbi:mysql:slave1', 'user', 'pass'],
            ['dbi:mysql:slave2', 'user', 'pass'],
            ['dbi:mysql:slave3', 'user', 'pass'],
        ],
        balancer_args => {
          master_read_weight => 0.3
        }
    });

=head1 DESCRIPTION

Sets your storage_type to L<DBIx::Class::Storage::DBI::Replicated> and connects
replicants provided in config. See that module for supported resultset
attributes.

The default L<DBIx::Class::Storage::DBI::Replicated/balancer_type> is
C<::Random>.

Sets the
L<DBIx::Class::Storage::DBI::Replicated::Balancer::Random/master_read_weight> to
C<1> by default, meaning that you have the same chance of reading from master as
you do from replicants. Set to C<0> to turn off reads from master.

=head1 CONFIG PARAMETERS

=head2 replicants

Array of connect_info settings for every replicant.

=cut

has replicants => (
    is => 'ro', isa => ConnectInfos, coerce => 1, required => 1
);

after setup => sub {
    my $self = shift;

# check storage_type compatibility (if configured)
    if (my $storage_type = $self->storage_type) {
        my $class = $storage_type =~ /^::/ ?
            "DBIx::Class::Storage$storage_type"
            : $storage_type;

        croak "This storage_type cannot be used with replication"
            unless $class->isa('DBIx::Class::Storage::DBI::Replicated');
    } else {
        $self->storage_type('::DBI::Replicated');
    }

    $self->connect_info->{balancer_type} ||= '::Random'
        unless $self->connect_info->{balancer_type};

    unless ($self->connect_info->{balancer_args} &&
            exists $self->connect_info->{balancer_args}{master_read_weight}) {
        $self->connect_info->{balancer_args}{master_read_weight} = 1;
    }
};

my $build = sub {
    my $self = shift;

    $self->storage->connect_replicants(map [ $_ ], $self->replicants->flatten);
};
after BUILD => $build;
sub BUILD { goto $build }

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<DBIx::Class>,
L<DBIx::Class::Storage::DBI::Replicated>,
L<Cache::FastMmap>, L<DBIx::Class::Cursor::Cached>

=head1 AUTHOR

Rafael Kitover, C<rkitover at cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
