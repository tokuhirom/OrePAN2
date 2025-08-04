package OrePAN2::Index;

use autodie;
use utf8;

use IO::Uncompress::Gunzip qw( $GunzipError );
use OrePAN2                ();
use version;
use OrePAN2::Logger;

use Moo;
use Types::Standard qw( HashRef );
use namespace::clean;

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

#@type OrePAN2::Logger
has log => (
    is      => 'ro',
    lazy    => 1,
    default => sub { my ($self) = @_; OrePAN2::Logger->new->get_logger() }
);

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

=item C<< $index->as_string() >>

Returns the content of the index as a string.  Some of the index metadata can
cause merge conflicts when multiple developers are working on the same project.
You can avoid this problem by using a paring down the metadata.  "simple"
defaults to 0.

    $index->as_string( simple => 1 );

Make index as string.

=back
