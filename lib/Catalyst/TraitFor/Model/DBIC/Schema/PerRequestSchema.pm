package Catalyst::TraitFor::Model::DBIC::Schema::PerRequestSchema;
use Moose;
use namespace::autoclean;

sub BUILD {}
after BUILD => sub {
    my ($self) = @_;
    confess("You have not implemented a per_request_schema_attributes method in " . ref($self))
        unless $self->can('per_request_schema_attributes');
};

with 'Catalyst::Component::InstancePerContext';

sub build_per_context_instance {
    my ( $self, $ctx ) = @_;
    return $self unless blessed($ctx);

    my $new = bless {%$self}, ref $self;

    $new->schema( $new->schema->clone($self->per_request_schema_attributes($ctx)) );

    return $new;
}

__PACKAGE__->meta->make_immutable;

