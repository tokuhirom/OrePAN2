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
use PerlIO::gzip;
use CPAN::Meta 2.131560;
use File::pushd;
use Parse::LocalDistribution;

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

    my $provides = $self->scan_provides($tmpdir);
    while (my ($package, $dat) = each %$provides) {
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
    my ($self, $dir) = @_;

    my $guard = pushd(glob("$dir/*"));

    my $metajson = "META.json";
    my $metayaml = "META.yml";
    my $meta;
    if (-f 'META.json') {
        $meta = CPAN::Meta->load_file('META.json');
        if ($meta->{provides}) {
            print "Got provided packages information from META\n";
            return $meta->{provides};
        }
        # fallthrough.
    } elsif (-f 'META.yml') {
        $meta = CPAN::Meta->load_file('META.yml');
    } else {
        print "[WARN] META file does not exists in $dir\n";
    }

    return $self->_scan_provides('.', $meta);
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
    open my $fh, $no_compress ? '>:raw' : '>:gzip', $pkgfname,
        or die "Cannot open $pkgfname for writing: $!\n";
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

