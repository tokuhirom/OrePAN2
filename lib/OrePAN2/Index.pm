package OrePAN2::Index;
use strict;
use warnings;
use utf8;
use OrePAN2;
use IO::Compress::Gzip ('$GzipError');

use Class::Accessor::Lite 0.05 (
    rw => [qw(no_mtime)],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
        index => [],
        no_mtime => 0,
    }, $class;
}

sub load {
    my ($class, $fname) = @_;

    my $self = $class->new();

    my $fh = do {
        if ($fname =~ /\.gz\z/) {
            IO::Compress::Gzip->new($fname)
                or die "gzip failed: $GzipError\n";
        } else {
            open my $fh, '<', $fname
                or Carp::croak("Cannot open '$fname' for reading: $!");
            $fh;
        }
    };

    # skip headers
    while (<$fh>) {
        last unless /\S/;
    }

    while (<$fh>) {
        if (/^(\S+)\s+(\S+)\s+(.*)$/) {
            push @{$self->{index}}, [$1,$2 eq 'undef' ? undef : $2,$3];
        }
    }

    close $fh;

    return $self;
}

sub lookup {
    my ($self, $package) = @_;
    for (@{$self->{index}}) {
        return ($_->[1], $_->[2]) if $_->[0] eq $package;
    }
    return;
}

sub add_index {
    my ($self, $package, $version, $archive_file) = @_;

    push @{$self->{index}}, [$package, $version, $archive_file];
}

sub as_string {
    my $self = shift;

    my @buf;

    push @buf, (
        'File:         02packages.details.txt',
        'URL:          http://www.perl.com/CPAN/modules/02packages.details.txt',
        'Description:  DarkPAN',
        'Columns:      package name, version, path',
        'Intended-For: Automated fetch routines, namespace documentation.',
        "Written-By:   OrePAN2 $OrePAN2::VERSION",
        "Line-Count:   @{[ scalar(@{$self->{index}}) ]}",
        (!$self->{no_mtime} ? "Last-Updated: @{[ scalar localtime ]}" : ()),
        '',
    );

    for my $row (sort { $a->[0] cmp $b->[0] } @{$self->{index}}) {
        # package name, version, path
        push @buf, sprintf "%-22s %-22s %s", $row->[0], $row->[1] || 'undef', $row->[2];
    }
    return join("\n", @buf) . "\n";
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

=item C<< my $index = OrePAN2::Index->load($filename) >>

Load existing 02.packages.details.txt

=item C<< my ($version, $path) = $index->lookup($package) >>

Lookup package from index.

=item C<< $index->add_index($package, $version, $path) >>

Add new entry to the index.

=item C<< $index->as_string() >>

Make index as string.

=back
