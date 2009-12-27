package Catalyst::TraitFor::Model::DBIC::Schema::SchemaProxy;

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::SchemaProxy - Proxy Schema Methods and
Options from Model

=head1 DESCRIPTION

Allows you to call L<DBIx::Class::Schema> methods directly on the Model
instance, and passes config options to the L<DBIx::Class::Schema> attributes at
C<BUILD> time.

This trait is loaded by default, but can be disabled by adding C<-SchemaProxy>
to the L<Catalyst::Model::DBIC::Schema/traits> array.

=cut

after setup => sub {
    my ($self, $args) = @_;

    my $was_mutable = $self->meta->is_mutable;

    $self->meta->make_mutable;
    $self->meta->add_attribute('schema',
        is => 'rw',
        isa => 'DBIx::Class::Schema',
        handles => $self->_delegates # this removes the attribute too
    );
    $self->meta->make_immutable unless $was_mutable;
};

after BUILD => sub {
    my ($self, $args) = @_;

    $self->_pass_options_to_schema($args);
};

sub _delegates {
    my $self = shift;

    my $schema_meta = Class::MOP::Class->initialize($self->schema_class);
    my @schema_methods = $schema_meta->get_all_method_names;

# combine with any already added by other schemas
    my @handles = eval {
        @{ $self->meta->find_attribute_by_name('schema')->handles }
    };

# now kill the attribute, otherwise add_attribute in BUILD will not do the right
# thing (it clears the handles for some reason.) May be a Moose bug.
    eval { $self->meta->remove_attribute('schema') };

    my %schema_methods;
    @schema_methods{ @schema_methods, @handles } = ();
    @schema_methods = keys %schema_methods;

    my @my_methods = $self->meta->get_all_method_names;
    my %my_methods;
    @my_methods{@my_methods} = ();

    my @delegates;
    for my $method (@schema_methods) {
        push @delegates, $method unless exists $my_methods{$method};
    }

    return \@delegates;
}

sub _pass_options_to_schema {
    my ($self, $args) = @_;

    my @attributes = map {
        $_->init_arg || ()
    } $self->meta->get_all_attributes;

    my %attributes;
    @attributes{@attributes} = ();

    for my $opt (keys %$args) {
        if (not exists $attributes{$opt}) {
            next unless $self->schema->can($opt);
            $self->schema->$opt($self->{$opt});
        }
    }
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
