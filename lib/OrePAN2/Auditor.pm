package OrePAN2::Auditor;

use Moo 1.007000;

use feature qw( say state );
use version 0.9912;

use Carp qw( croak );
use List::Compare ();
use MooX::Options;
use Parse::CPAN::Packages::Fast 0.09;
use Path::Tiny ();
use Text::SimpleTable::AutoWidth ();
use Type::Params qw( compile );
use Type::Tiny::Enum;
use Type::Utils qw( class_type );
use Types::Standard qw( ArrayRef Bool InstanceOf Str );
use Types::URI -all;
use LWP::UserAgent ();

my $SHOW = Type::Tiny::Enum->new(
    name => 'Show',
    values =>
        [ 'cpan-only-modules', 'darkpan-only-modules', 'outdated-modules', 'outdated-releases' ],
);

option cpan => (
    is       => 'ro',
    isa      => Uri,
    format   => 's',
    required => 1,
    coerce   => 1,
    doc      => 'the path to a CPAN 02packages file',
);

option darkpan => (
    is       => 'ro',
    isa      => Uri,
    format   => 's',
    required => 1,
    coerce   => 1,
    doc      => 'the path to your DarkPan 02packages file',
);

option show => (
    is     => 'ro',
    isa    => $SHOW,
    format => 's',
);

option verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has cpan_modules => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_modules_from_parser( $self->_cpan_parser );
    },
);

has darkpan_modules => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_modules_from_parser( $self->_darkpan_parser );
    },
);

has cpan_only_modules => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub {
        return [ shift->_list_compare->get_complement ];
    },
);

has darkpan_only_modules => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub {
        return [ shift->_list_compare->get_unique ];
    },
);

has outdated_modules => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    builder => '_build_outdated_modules',
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    default => sub {
        return LWP::UserAgent->new();
    },
);

has _cpan_parser => (
    is      => 'ro',
    isa     => InstanceOf ['Parse::CPAN::Packages::Fast'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_parser_for_url( $self->cpan );
    },
);

has _darkpan_parser => (
    is      => 'ro',
    isa     => InstanceOf ['Parse::CPAN::Packages::Fast'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_parser_for_url( $self->darkpan );
    },
);

has _list_compare => (
    is      => 'ro',
    isa     => InstanceOf ['List::Compare'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return List::Compare->new(
            $self->darkpan_modules,
            $self->cpan_modules
        );
    },
);

sub run {
    my $self = shift;

    my $method = $self->show;
    $method =~ s{-}{_}g;

    if ( $method eq 'outdated_releases' ) {
        $self->_outdated_releases;
        return;
    }

    my $modules = $self->$method;

    if ( $method eq 'outdated_modules' && $self->verbose ) {
        foreach my $module ( @{$modules} ) {
            my @row = (
                $module,
                $self->darkpan_module($module)->distribution->distvname,
                $self->cpan_module($module)->distribution->distvname,

                sprintf(
                    'https://metacpan.org/changes/distribution/%s',
                    $self->cpan_module($module)->distribution->dist
                ),
            );
            say join "\t", @row;
        }
        return;
    }

    say $_ for @{$modules};
}

sub _outdated_releases {
    my $self     = shift;
    my $outdated = $self->outdated_modules;

    my %dist;
    foreach my $module (@$outdated) {
        my $darkpan = $self->darkpan_module($module)->distribution;
        my $cpan    = $self->cpan_module($module)->distribution;

        next if $darkpan->distvname eq $cpan->distvname;

        $dist{ $darkpan->dist }->{ $darkpan->distvname }->{version}
            ->{ $cpan->distvname } = 1;
        push @{ $dist{ $darkpan->dist }->{ $darkpan->distvname }->{modules} },
            [ $module, $cpan->distvname ];
    }

    foreach my $dist_name ( sort keys %dist ) {
        foreach my $release ( keys %{ $dist{$dist_name} } ) {
            my $this_release = $dist{$dist_name}->{$release};
            my @versions     = sort keys %{ $this_release->{version} };

            say sprintf '%s => %s', $release, join '/', @versions;
            say "https://metacpan.org/changes/distribution/$dist_name";

            say q{} and next if scalar @versions == 1;

            my @modules
                = sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] }
                @{ $this_release->{modules} };
            my $table = Text::SimpleTable::AutoWidth->new;
            foreach my $module (@modules) {
                $table->row( $module->[0], $module->[1] );
            }
            say $table->draw;
        }
    }
}

sub cpan_module {
    my $self = shift;
    state $check = compile(Str);
    my ($module) = $check->(@_);

    return $self->_cpan_parser->package($module);
}

sub darkpan_module {
    my $self = shift;
    state $check = compile(Str);
    my ($module) = $check->(@_);

    return $self->_darkpan_parser->package($module);
}

sub _build_outdated_modules {
    my $self = shift;

    my $darkpan = $self->_darkpan_parser;
    my $cpan    = $self->_cpan_parser;

    my @outdated;
    for my $module ( $self->_list_compare->get_intersection ) {
        if ( version->parse( $darkpan->package($module)->version )
            < version->parse( $cpan->package($module)->version ) ) {
            push @outdated, $module;
        }
    }
    return \@outdated;
}

sub _modules_from_parser {
    my $self   = shift;
    my $parser = shift;

    return [ sort { $a cmp $b } $parser->packages ];
}

sub _parser_for_url {
    my $self = shift;
    my $url  = shift;

    $url->scheme('file') if !$url->scheme;

    my $res = $self->ua->get($url);
    croak "could not fetch $url" if !$res->is_success;

    # dumb hack to avoid having to uncompress this ourselves
    my @path_segments = $url->path_segments;

    my $err = <<"EOF";
    Path invalid for $url Please provide full path to 02packages file.
EOF
    croak $err if !@path_segments;

    my $tempdir = Path::Tiny->tempdir;
    my $child   = $tempdir->child( pop @path_segments );
    $child->spew_raw( $res->content );

    return Parse::CPAN::Packages::Fast->new( $child->stringify );
}

1;

__END__

=pod

=head1 SYNOPSIS

    my $auditor = OrePAN2::Auditor->new(
        cpan => 'https://cpan.metacpan.org/modules/02packages.details.txt',
        darkpan => '/full/path/to/darkpan/02packages.details.txt'
    );

    # ArrayRef of module names
    my $outdated_modules = $auditor->outdated_modules;

=head1 DESCRIPTION

If you have a local DarkPAN or MiniCPAN or something which has its own
C<02packages.txt> file, it can be helpful to know which files are outdated or
which files exist in your DarkPAN, but not on CPAN (or vice versa).  This
module makes this easy for you.

Think of it as a way of diffing C<02packages> files.

=head2 new

    my $auditor = OrePAN2::Auditor->new(
        cpan => 'https://cpan.metacpan.org/modules/02packages.details.txt',
        darkpan => '/full/path/to/darkpan/02packages.details.txt'
    );

The C<cpan> and C<darkpan> args are the only required arguments.  These can
either be a path on your filesystem or a full URL to the 02packages files which
you'd like to diff.

=head2 cpan_modules

An C<ArrayRef> of module names which exist currently on CPAN.

=head2 cpan_only_modules

An C<ArrayRef> of module names which exist currently on CPAN but not in your DarkPAN.

=head2 darkpan_modules

An C<ArrayRef> of module names which exist currently on your DarkPAN.

=head2 darkpan_only_modules

An C<ArrayRef> of module names which exist currently on your DarkPAN but not in CPAN.

=head2 outdated_modules

An C<ArrayRef> of module names which exist currently on both your DarkPAN and
on CPAN and for which the module in your DarkPAN has a lower version number.

=head2 cpan_module( $module_name )

    my $module = $auditor->cpan_module( 'HTML::Restrict' );

Returns a L<Parse::CPAN::Packages::Fast::Package> object.

=head2 darkpan_module( $module_name )

    my $module = $auditor->cpan_module( 'HTML::Restrict' );

Returns a L<Parse::CPAN::Packages::Fast::Package> object.

=cut
