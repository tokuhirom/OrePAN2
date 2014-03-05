package OrePAN2::Index;
use strict;
use warnings;
use utf8;
use OrePAN2;
use IO::Uncompress::Gunzip ('$GunzipError');

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
        index => {},
        %args,
    }, $class;
}

sub load {
    my ($self, $fname, $opts) = @_;
    $opts ||= {};

    my $fh = do {
        if ($fname =~ /\.gz\z/) {
            IO::Uncompress::Gunzip->new($fname)
                or die "gzip failed: $GunzipError\n";
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
           $self->add_index($1,$2 eq 'undef' ? undef : $2,$3);
        }
    }

    close $fh;
}

sub lookup {
    my ($self, $package) = @_;
    if (my $entry = $self->{index}->{$package}) {
        return @$entry;
    }
    return;
}

sub packages {
    my ($self) = @_;
    sort { $a cmp $b } keys %{$self->{index}};
}

sub delete_index {
    my ($self, $package) = @_;
    delete $self->{index}->{$package};
    return;
}

sub add_index {
    my ($self, $package, $version, $archive_file) = @_;

    if ($self->{index}{$package}) {
        my ($orig_ver) = @{$self->{index}{$package}};
        if (version->parse($orig_ver) >= version->parse($version)) {
            return;
        }
    }
    $self->{index}->{$package} = [$version, $archive_file];
}

sub as_string {
    my ($self, $opts) = @_;
    $opts ||= +{};
    my $simple = $opts->{simple} || 0;

    my @buf;

    push @buf, (
        'File:         02packages.details.txt',
        'URL:          http://www.perl.com/CPAN/modules/02packages.details.txt',
        'Description:  DarkPAN',
        'Columns:      package name, version, path',
        'Intended-For: Automated fetch routines, namespace documentation.',
        $simple ? () : (
            "Written-By:   OrePAN2 $OrePAN2::VERSION",
            "Line-Count:   @{[ scalar(keys %{$self->{index}}) ]}",
            "Last-Updated: @{[ scalar localtime ]}",
        ),
        '',
    );

    for my $pkg ($self->packages) {
        my $entry = $self->{index}{$pkg};
        # package name, version, path
        push @buf, sprintf "%-22s %-22s %s", $pkg, $entry->[0] || 'undef', $entry->[1];
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

=item C<< $index->load($filename) >>

Load existing 02.packages.details.txt

=item C<< my ($version, $path) = $index->lookup($package) >>

Lookup package from index.

=item C<< $index->add_index($package, $version, $path) >>

Add new entry to the index.

=item C<< $index->as_string() >>

Make index as string.

=back
