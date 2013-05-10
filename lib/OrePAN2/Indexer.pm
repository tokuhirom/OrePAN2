package OrePAN2::Indexer;
use strict;
use warnings;
use utf8;

use File::Find qw(find);
use Module::Metadata ();
use File::Spec ();
use File::Basename ();
use Archive::Extract ();
use OrePAN2::Index;
use File::Temp qw(tempdir);
use PerlIO::gzip;
use CPAN::Meta;

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
    my $self = shift;

    my @files = $self->list_archive_files();
    my $index = OrePAN2::Index->new();
    for my $archive_file (@files) {
        $self->add_index($index, $archive_file);
    }
    $self->write_index($index);
}

sub add_index {
    my ($self, $index, $archive_file) = @_;

    my $archive = Archive::Extract->new(
        archive => $archive_file
    );
    my $tmpdir = tempdir( CLEANUP => 1 );
    $archive->extract( to => $tmpdir);

    my $provides = $self->scan_provides($tmpdir);
    while (my ($package, $data) = each %$provides) {
        my $version = $provides->{$package}->{version};
        $index->add_index(
            $package,
            $version,
            File::Spec->abs2rel($archive_file, File::Spec->catfile($self->directory, 'authors', 'id')),
        );
    }
}

sub scan_provides {
    my ($self, $dir) = @_;

    my $metafname = glob("$dir/*/META.json");
    if (-f $metafname) {
        my $meta = CPAN::Meta->load_file($metafname);
        if ($meta->{provides}) {
            print "Got provided packages information from META\n";
            return $meta->{provides};
        }
        # fallthrough.
    }

    print "Getting provided packages information by Module::Metadata\n";
    return Module::Metadata->provides(
        dir => $dir,
        version => 2,
    );
}

sub write_index {
    my ($self, $index) = @_;

    my $pkgfname = File::Spec->catfile($self->directory, 'modules', '02packages.details.txt.gz');
    mkdir(File::Basename::dirname($pkgfname));
    open my $fh, '>:gzip', $pkgfname,
        or die "Cannot open $pkgfname for writing: $!\n";
    print $fh $index->as_string();
    close $fh;
}

sub list_archive_files {
    my $self = shift;

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
        }, File::Spec->catfile($self->{directory}, 'authors')
    );
    return @files;
}

1;

