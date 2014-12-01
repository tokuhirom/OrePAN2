package OrePAN2::Indexer;

use strict;
use warnings;
use utf8;

use Archive::Extract ();
use CPAN::Meta 2.131560;
use Class::Accessor::Lite ( rw => ['_metacpan_lookup'] );
use File::Basename ();
use File::Find qw(find);
use File::Spec ();
use File::Temp qw(tempdir);
use File::pushd;
use IO::Zlib;
use MetaCPAN::Client;
use OrePAN2::Index;
use Parse::LocalDistribution;
use Path::Tiny;
use Try::Tiny;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    unless ( defined $args{directory} ) {
        Carp::croak('Missing mandatory parameter: directory');
    }
    bless {
        %args,
    }, $class;
}

sub directory { shift->{directory} }

sub make_index {
    my ( $self, %args ) = @_;

    my @files = $self->list_archive_files();

    if ( $self->{metacpan} ) {
        try {
            $self->do_metacpan_lookup( \@files );
        }
        catch {
            print STDERR "[WARN] Unable to fetch provides via MetaCPAN\n";
            print STDERR "[WARN] $_\n";
        };
    }

    my $index = OrePAN2::Index->new();
    for my $archive_file (@files) {
        $self->add_index( $index, $archive_file );
    }
    $self->write_index( $index, $args{no_compress} );
    return $index;
}

sub add_index {
    my ( $self, $index, $archive_file ) = @_;

    return if $self->_maybe_index_from_metacpan( $index, $archive_file );

    my $archive = Archive::Extract->new( archive => $archive_file );
    my $tmpdir = tempdir( CLEANUP => 1 );
    $archive->extract( to => $tmpdir );

    my $provides = $self->scan_provides( $tmpdir, $archive_file );
    my $path = $self->_orepan_archive_path($archive_file);

    foreach my $package ( sort keys %{$provides} ) {
        $index->add_index(
            $package,
            $provides->{$package}->{version},
            $path,
        );
    }
}

sub _orepan_archive_path {
    my $self         = shift;
    my $archive_file = shift;
    my $path         = File::Spec->abs2rel(
        $archive_file,
        File::Spec->catfile( $self->directory, 'authors', 'id' )
    );
    $path =~ s!\\!/!g;
    return $path;
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

sub _maybe_index_from_metacpan {
    my ( $self, $index, $file ) = @_;

    return unless $self->{metacpan};

    my $archive = Path::Tiny->new($file)->basename;
    my $lookup  = $self->_metacpan_lookup;

    unless ( exists $lookup->{archive}->{$archive} ) {
        print STDERR "[INFO] $archive not found on MetaCPAN\n";
        return;
    }
    my $release_name = $lookup->{archive}->{$archive};

    my $provides = $lookup->{release}->{$release_name};
    unless ( $provides && keys %{$provides} ) {
        print STDERR "[INFO] provides for $archive not found on MetaCPAN\n";
        return;
    }

    my $path = $self->_orepan_archive_path($file);

    foreach my $package ( keys %{$provides} ) {
        $index->add_index( $package, $provides->{$package}, $path, );
    }
    return 1;
}

sub do_metacpan_lookup {
    my ( $self, $files ) = @_;

    return unless @{$files};

    my $provides = $self->_metacpan_lookup;

    my $mc                 = MetaCPAN::Client->new;
    my @archives           = map { Path::Tiny->new($_)->basename } @{$files};
    my @search_by_archives = map { +{ archive => $_ } } @archives;
    my $releases = $mc->release( { either => \@search_by_archives } );

    my @file_search;

    while ( my $release = $releases->next ) {

        $provides->{archive}->{ $release->archive } = $release->name;

        push @file_search,
            {
            all => [
                { release               => $release->name },
                { indexed               => 'true' },
                { authorized            => 'true' },
                { 'file.module.indexed' => 'true' },
            ]
            };
    }

    my $modules = $mc->module( { either => \@file_search } );

    while ( my $file = $modules->next ) {
        next unless $file->module;
        foreach my $inner ( @{ $file->module } ) {
            next unless $inner->{indexed};

            $provides->{release}->{ $file->release }->{ $inner->{name} } //=
                $inner->{version_numified};
        }
    }

    $self->_metacpan_lookup($provides);
}

sub _scan_provides {
    my ( $self, $dir, $meta ) = @_;

    my $provides = Parse::LocalDistribution->new->parse($dir);
    return $provides;
}

sub write_index {
    my ( $self, $index, $no_compress ) = @_;

    my $pkgfname = File::Spec->catfile(
        $self->directory,
        'modules',
        $no_compress ? '02packages.details.txt' : '02packages.details.txt.gz'
    );
    mkdir( File::Basename::dirname($pkgfname) );
    my $fh = do {
        if ($no_compress) {
            open my $fh, '>:raw', $pkgfname;
            $fh;
        }
        else {
            IO::Zlib->new( $pkgfname, 'w' )
                or die "Cannot open $pkgfname for writing: $!\n";
        }
    };
    print $fh $index->as_string( { simple => $self->{simple} } );
    close $fh;
}

sub list_archive_files {
    my $self = shift;

    my $authors_dir = File::Spec->catfile( $self->{directory}, 'authors' );
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
        },
        $authors_dir
    );

    # Sort files by modication time so that we can index distributions from
    # earliest to latest version.

    return sort { -M $b <=> -M $a } @files;
}

1;

