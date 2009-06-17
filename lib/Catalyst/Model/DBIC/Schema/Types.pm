package  # hide from PAUSE
    Catalyst::Model::DBIC::Schema::Types;

use MooseX::Types -declare => [qw/
    ConnectInfo ConnectInfos Replicants LoadedClass CreateOption
/];

use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use MooseX::Types::Moose qw/ArrayRef HashRef Str ClassName/;
use Scalar::Util 'reftype';
use List::MoreUtils 'all';

use namespace::clean -except => 'meta';

class_type 'DBIx::Class::Schema';

subtype LoadedClass,
    as ClassName;

coerce LoadedClass,
    from Str,
    via { Class::MOP::load_class($_); $_ };

subtype ConnectInfo,
    as HashRef,
    where { exists $_->{dsn} },
    message { 'Does not look like a valid connect_info' };

coerce ConnectInfo,
    from Str,
    via(\&_coerce_connect_info_from_str),
    from ArrayRef,
    via(\&_coerce_connect_info_from_arrayref);

# { connect_info => [ ... ] } coercion would be nice, but no chained coercions
# yet.
# Also no coercion from base type (yet,) but in Moose git already.
#    from HashRef,
#    via { $_->{connect_info} },

subtype ConnectInfos,
    as ArrayRef[ConnectInfo],
    message { "Not a valid array of connect_info's" };

coerce ConnectInfos,
    from Str,
    via  { [ _coerce_connect_info_from_str() ] },
    from ArrayRef,
    via { [ map {
        !ref $_ ? _coerce_connect_info_from_str()
            : reftype $_ eq 'HASH' ? $_
            : reftype $_ eq 'ARRAY' ? _coerce_connect_info_from_arrayref()
            : die 'invalid connect_info'
    } @$_ ] };

# Helper stuff

subtype CreateOption,
    as Str,
    where { /^(?:static|dynamic)\z/ },
    message { "Invalid create option, must be one of 'static' or 'dynamic'" };

sub _coerce_connect_info_from_arrayref {
    my %connect_info;

    # make a copy
    $_ = [ @$_ ];

    if (!ref $_->[0]) { # array style
        $connect_info{dsn}      = shift @$_;
        $connect_info{user}     = shift @$_ if !ref $_->[0];
        $connect_info{password} = shift @$_ if !ref $_->[0];

        for my $i (0..1) {
            my $extra = shift @$_;
            last unless $extra;
            die "invalid connect_info" unless reftype $extra eq 'HASH';

            %connect_info = (%connect_info, %$extra);
        }

        die "invalid connect_info" if @$_;
    } elsif (@$_ == 1 && reftype $_->[0] eq 'HASH') {
        return $_->[0];
    } else {
        die "invalid connect_info";
    }

    for my $key (qw/user password/) {
        $connect_info{$key} = ''
            if not defined $connect_info{$key};
    }

    \%connect_info;
}

sub _coerce_connect_info_from_str {
    +{ dsn => $_, user => '', password => '' }
}

1;
