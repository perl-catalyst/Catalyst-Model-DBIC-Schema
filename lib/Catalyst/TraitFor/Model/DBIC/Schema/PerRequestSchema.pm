package Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema;
use Moose::Role;
use namespace::autoclean;

requires 'per_request_schema_attributes';

with 'Catalyst::Component::InstancePerContext';

sub build_per_context_instance {
    my ( $self, $ctx ) = @_;
    return $self unless blessed($ctx);

    my $new = bless {%$self}, ref $self;

    $new->schema( $new->schema->clone($self->per_request_schema_attributes($ctx)) );

    return $new;
}

__PACKAGE__->meta->make_immutable;

