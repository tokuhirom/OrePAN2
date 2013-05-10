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
use Parse::PMFile;
use File::pushd;

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
    while (my ($package, $dat) = each %$provides) {
        my $version = $dat->{version};
        $index->add_index(
            $package,
            $version,
            File::Spec->abs2rel($archive_file, File::Spec->catfile($self->directory, 'authors', 'id')),
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
    }

    my @files = $self->list_pm_files('.', $meta);
    # local $Parse::PMFile::VERBOSE=100;
    my $pmfile = Parse::PMFile->new($meta ? $meta : +{});
    my $result;
    LOOP: for my $file (@files) {
        my $dat = $pmfile->parse($file);
        while (my ($pkg, $dat) = each %$dat) {
            $result->{$pkg} = $dat;
        }
    }
    return $result;
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

sub list_pm_files {
    my ($self, $directory, $meta) = @_;

    my @files;
    find(
        {
            wanted => sub {
                return unless /
                    (?:
                        \.pm
                    )
                \z/x;
                my $rel = File::Spec->abs2rel($_, $directory);
                if ($meta && $meta->{no_index}->{directory}) {
                    my @no_index_dirs = @{$meta->{no_index}->{directory}};
                    for my $no_index (@no_index_dirs) {
                        if ([File::Spec->splitdir($rel)]->[0] eq $no_index) {
                            print "Ignore $rel by no_index: $no_index\n";
                            return;
                        }
                    }
                }
                push @files, $rel;
            },
            no_chdir => 1,
        }, $directory
    );
    return @files;
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

