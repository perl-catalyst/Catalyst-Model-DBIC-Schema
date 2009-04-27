package Catalyst::Model::DBIC::Schema::Types;

use MooseX::Types
    -declare => [qw/ConnectInfo SchemaClass/];

use MooseX::Types::Moose qw/ArrayRef HashRef Str ClassName/;
use Scalar::Util 'reftype';
use Carp;

use namespace::clean -except => 'meta';

subtype SchemaClass,
    as ClassName;

coerce SchemaClass,
    from Str,
    via { Class::MOP::load_class($_); $_ };

subtype ConnectInfo,
    as HashRef,
    where { exists $_->{dsn} },
    message { 'Does not look like a valid connect_info' };

coerce ConnectInfo,
    from Str,
    via { +{ dsn => $_ } },
    from ArrayRef,
    via {
        my %connect_info;

        if (!ref $_->[0]) { # array style
            $connect_info{dsn}      = shift @$_;
            $connect_info{user}     = shift @$_ if !ref $_->[0];
            $connect_info{password} = shift @$_ if !ref $_->[0];

            for my $i (0..1) {
                my $extra = shift @$_;
                last unless $extra;
                croak "invalid connect_info" unless reftype $extra eq 'HASH';

                %connect_info = (%connect_info, %$extra);
            }

            croak "invalid connect_info" if @$_;
        } elsif (@$_ == 1 && reftype $_->[0] eq 'HASH') {
            return $_->[0];
        } else {
            croak "invalid connect_info";
        }

        \%connect_info;
};

# { connect_info => [ ... ] } coercion would be nice, but no chained coercions
# yet and no coercion from subtype (yet) but in Moose git already.
#    from HashRef,
#    via { $_->{connect_info} },

1;
