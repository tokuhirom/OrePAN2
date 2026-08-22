package OrePAN2::Index;

use autodie;
use utf8;

use IO::Uncompress::Gunzip qw( $GunzipError );
use OrePAN2                ();
use version;
use OrePAN2::Logger;

use Moo;
with 'OrePAN2::Role::HasLogger';
use Types::Standard qw( HashRef );
use namespace::clean;
use IO::Compress::Gzip qw( $GzipError );
use Path::Tiny ();

has index => ( is => 'ro', isa => HashRef, default => sub { +{} } );

sub load {
    my ( $self, $fname ) = @_;

    my $fh = do {
        if ( $fname =~ /\.gz\z/ ) {
            IO::Uncompress::Gunzip->new($fname)
                or die "gzip failed: $GunzipError\n";
        }
        else {
            open my $fh, '<', $fname;
            $fh;
        }
    };

    # skip headers
    while (<$fh>) {
        last unless /\S/;
    }

    while (<$fh>) {
        if (/^(\S+)\s+(\S+)\s+(.*)$/) {
            $self->add_index( $1, $2 eq 'undef' ? undef : $2, $3 );
        }
    }

    close $fh;
}

sub lookup {
    my ( $self, $package ) = @_;
    if ( my $entry = $self->index->{$package} ) {
        return @$entry;
    }
    return;
}

sub packages {
    my ($self) = @_;
    sort { lc $a cmp lc $b } keys %{ $self->index };
}

sub delete_index {
    my ( $self, $package ) = @_;
    delete $self->index->{$package};
    return;
}

# Order of preference is last updated. So if some modules maintain the same
# version number across multiple uploads, we'll point to the module in the
# latest archive.

sub add_index {
    my ( $self, $package, $version, $archive_file ) = @_;

    if ( $self->index->{$package} ) {
        my ($orig_ver) = @{ $self->index->{$package} };

        if ( version->parse($orig_ver) > version->parse($version) ) {
            $version //= 'undef';
            $self->log->info("Not adding $package in $archive_file");
            $self->log->info(
                "Existing version $orig_ver is greater than $version");
            return;
        }
    }
    $self->index->{$package} = [ $version, $archive_file ];
}

sub merge {
    my ( $self, $other, %opts ) = @_;

    my %protected_author
        = map { uc($_) => 1 } grep {length} @{ $opts{protect_author} || [] };
    my %protected_package;
    if (%protected_author) {
        my %matched_author;
        for my $package ( $self->packages ) {
            my (undef, $path) = $self->lookup($package);
            next unless defined $path;
            my ($author) = $path =~ m{\A[^/]+/[^/]+/([^/]+)/};
            next unless defined $author && $protected_author{ uc($author) };
            $protected_package{$package} = 1;
            $matched_author{ uc($author) } = 1;
        }
        for my $author ( sort keys %protected_author ) {
            $self->log->warn(
                "protect_author '$author' matched no packages in this index"
            ) unless $matched_author{$author};
        }
    }

    for my $package ( $other->packages ) {
        next if $protected_package{$package};
        my ( $version, $archive_file ) = $other->lookup($package);
        $self->add_index( $package, $version, $archive_file );
    }
    return;
}

sub as_string {
    my ( $self, $opts ) = @_;
    $opts ||= +{};
    my $simple = $opts->{simple} || 0;

    my @buf;

    push @buf,
        (
        'File:         02packages.details.txt',
        'URL:          http://www.perl.com/CPAN/modules/02packages.details.txt',
        'Description:  DarkPAN',
        'Columns:      package name, version, path',
        'Intended-For: Automated fetch routines, namespace documentation.',
        $simple
        ? ()
        : (
            "Written-By:   OrePAN2 $OrePAN2::VERSION",
            "Line-Count:   @{[ scalar(keys %{$self->index}) ]}",
            "Last-Updated: @{[ scalar localtime ]}",
        ),
        q{},
        );

    for my $pkg ( $self->packages ) {
        my $entry = $self->index->{$pkg};

        # package name, version, path
        push @buf, sprintf '%-22s %-22s %s', $pkg, $entry->[0] || 'undef',
            $entry->[1];
    }
    return join( "\n", @buf ) . "\n";
}

sub write_gzip {
    my ( $self, $path, $opts ) = @_;

    my $gzipped;
    my $gz = IO::Compress::Gzip->new( \$gzipped, Time => 0 )
        or die "Cannot create gzip stream: $GzipError\n";
    $gz->print( $self->as_string($opts) )
        or die "gzip print failed: $GzipError\n";
    $gz->close
        or die "gzip close failed: $GzipError\n";
    Path::Tiny::path($path)->spew_raw($gzipped);
    return;
}

1;
__END__

=head1 NAME

OrePAN2::Index - Index

=head1 DESCRIPTION

This is a module to manipulate 02packages.details.txt.

=head1 METHODS

=over 4

=item C<< my $index = OrePAN2::Index->new(%attr) >>

=item C<< $index->load($filename) >>

Load an existing 02.packages.details.txt

=item C<< my ($version, $path) = $index->lookup($package) >>

Perform a package lookup on the index.

=item C<< $index->delete_index($package) >>

Delete a package from the index.

=item C<< $index->add_index($package, $version, $path) >>

Add a new entry to the index.

=item C<< $index->merge($other_index, protect_author => \@pause_ids) >>

Merge every package from C<$other_index> into C<$index>, in place. Ordinary
merges use C<add_index>'s "higher version wins" semantics.

C<protect_author> is an optional list of PAUSE ids. Any package already in
C<$index> whose entry's path is authored by one of these ids (i.e. the path
looks like C<X/XX/AUTHORID/...>) keeps its C<$index> entry, even if
C<$other_index> has a numerically higher version of the same package.
Matching is case-insensitive.

Protection is applied per I<package>, not per I<distribution>: if
C<$other_index> provides a package that C<$index>'s copy of a protected
author's distribution doesn't, that package is still taken from
C<$other_index>.

If a given C<protect_author> id matches zero packages in C<$index> (a typo,
or nothing from that author is in the index yet), a warning is logged -- it
doesn't fail the merge, but it means that id currently protects nothing.

=item C<< $index->as_string() >>

Returns the content of the index as a string.  Some of the index metadata can
cause merge conflicts when multiple developers are working on the same project.
You can avoid this problem by using a paring down the metadata.  "simple"
defaults to 0.

    $index->as_string( simple => 1 );

Make index as string.

=item C<< $index->write_gzip( $path, \%options ) >>

Writes the index, gzip-compressed, to the file at C<$path>, replacing any
existing file there. The write is atomic: concurrent readers see either the
old file or the complete new one, never a partial write. C<%options> is
forwarded verbatim to L</as_string>.

    $index->write_gzip( $path, { simple => 1 } );

=back
