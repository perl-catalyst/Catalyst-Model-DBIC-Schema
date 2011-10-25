package Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema;

use Moose::Role;
use namespace::autoclean;

requires 'per_request_schema_attributes';

with 'Catalyst::Component::InstancePerContext';

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema - Clone the schema
with attributes for each requests

=head1 SYNOPSIS

    __PACKAGE__->config({
        traits => ['PerRequestSchema'],
    });

    method per_request_schema_attributes($c) {
        return (restricting_object => $c->user->obj);
    }

=head1 DESCRIPTION

Clones the schema for each new request with the attributes retrieved from your
C<per_request_schema_attributes> method, which you must implement. This method
is passed the context.

=cut

sub build_per_context_instance {
    my ( $self, $ctx ) = @_;
    return $self unless blessed($ctx);

    my $new = bless {%$self}, ref $self;

    $new->schema($new->schema->clone($self->per_request_schema_attributes($ctx)));

    return $new;
}

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<DBIx::Class::Schema>

=head1 AUTHOR

See L<Catalyst::Model::DBIC::Schema/AUTHOR> and
L<Catalyst::Model::DBIC::Schema/CONTRIBUTORS>.

=head1 COPYRIGHT

See L<Catalyst::Model::DBIC::Schema/COPYRIGHT>.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
