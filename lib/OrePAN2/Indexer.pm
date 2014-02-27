package OrePAN2::Indexer;
use strict;
use warnings;
use utf8;

use File::Find qw(find);
use File::Spec ();
use File::Basename ();
use Archive::Extract ();
use OrePAN2::Index;
use File::Temp qw(tempdir);
use CPAN::Meta 2.131560;
use File::pushd;
use Parse::LocalDistribution;
use IO::Zlib;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    unless (defined $args{directory}) {
        Carp::croak("Missing mandatory parameter: directory");
    }
    bless {
        %args,
    }, $class;
}

sub directory { shift->{directory} }

sub make_index {
    my ($self, %args) = @_;

    my @files = $self->list_archive_files();
    my $index = OrePAN2::Index->new();
    for my $archive_file (@files) {
        $self->add_index($index, $archive_file);
    }
    $self->write_index($index, $args{no_compress});
}

sub add_index {
    my ($self, $index, $archive_file) = @_;

    my $archive = Archive::Extract->new(
        archive => $archive_file
    );
    my $tmpdir = tempdir( CLEANUP => 1 );
    $archive->extract( to => $tmpdir);

    my $provides = $self->scan_provides( $tmpdir, $archive_file );
    while ( my ( $package, $dat ) = each %$provides ) {
        my $version = $dat->{version};
        my $path = File::Spec->abs2rel($archive_file, File::Spec->catfile($self->directory, 'authors', 'id'));
        $path =~ s!\\!/!g;
        $index->add_index(
            $package,
            $version,
            $path,
        );
    }
}

sub scan_provides {
    my ( $self, $dir, $archive_file ) = @_;

    my $guard = pushd( glob("$dir/*") );

    for my $mfile ( 'META.json', 'META.yml', 'META.yaml' ) {
        next unless -f $mfile;
        my $meta = eval { CPAN::Meta->load_file($mfile) };
        return $meta->{provides} if $meta && $meta->{provides};

        if ($@) {
            print STDERR "[WARN] Error using '$mfile' from '$archive_file'\n";
            print STDERR "[WARN] $@\n";
            print STDERR "[WARN] Attempting to continue...\n";
        }
    }

    print STDERR "[INFO] Could not find useful meta from '$archive_file'\n";
    print STDERR "[INFO] Scanning for provided modules...\n";

    my $provides = eval { $self->_scan_provides('.') };
    return $provides if $provides;

    print STDERR "[WARN] Error scanning: $@\n";
    # Return empty provides.
    return {};
}

sub _scan_provides {
    my ($self, $dir, $meta) = @_;

    my $provides = Parse::LocalDistribution->new->parse($dir);
    return $provides;
}

sub write_index {
    my ($self, $index, $no_compress) = @_;

    my $pkgfname = File::Spec->catfile(
        $self->directory,
        'modules',
        $no_compress ? '02packages.details.txt' : '02packages.details.txt.gz'
    );
    mkdir(File::Basename::dirname($pkgfname));
    my $fh = do {
        if ($no_compress) {
            open my $fh, '>:raw', $pkgfname
                or die "Cannot open $pkgfname for writing: $!\n";
            $fh;
        } else {
            IO::Zlib->new($pkgfname, "w")
                or die "Cannot open $pkgfname for writing: $!\n";
        }
    };
    print $fh $index->as_string();
    close $fh;
}

sub list_archive_files {
    my $self = shift;


    my $authors_dir = File::Spec->catfile($self->{directory}, 'authors');
    return () unless -d $authors_dir;

    my @files;
    find(
        {
            wanted => sub {
                return unless /
                    (?:
                          \.tar\.gz
                        | \.tgz
                        | \.zip
                    )
                \z/x;
                push @files, $_;
            },
            no_chdir => 1,
        }, $authors_dir
    );
    return @files;
}

1;

