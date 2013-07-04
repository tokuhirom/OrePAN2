package OrePAN2::Injector;
use strict;
use warnings;
use utf8;
use File::Temp qw(tempdir);
use File::pushd;
use CPAN::Meta;
use File::Spec;
use File::Path qw(mkpath);
use File::Basename qw(dirname basename);
use File::Find qw(find);
use Archive::Tar;
use HTTP::Tiny;
use File::Copy qw(copy);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    unless (exists $args{directory}) {
        Carp::croak("Missing directory");
    }
    bless {
        author => 'DUMMY',
        %args
    }, $class;
}

sub directory { shift->{directory} }

sub inject {
    my ($self, $source) = @_;
    
    if ($source =~ m{\A((?:git://|git\@github.com:).*?)(?:\@(.*))?\z}) {
        $self->inject_from_git($1, $2);
    } elsif ($source =~ m{\Ahttp://}) {
        $self->inject_from_http($source);
    } elsif (-f $source) {
        $self->inject_from_file($source);
    } else {
        die "Unknown source: $source\n";
    }
}

sub tarpath {
    my ($self, $basename) = @_;

    my $tarpath = File::Spec->catfile($self->directory, 'authors', 'id',
        substr($self->{author}, 0, 1),
        substr($self->{author}, 0, 2),
        $self->{author},
        $basename);
    mkpath(dirname($tarpath));

    return $tarpath;
}

sub inject_from_file {
    my ($self, $file) = @_;

    my $basename = basename($file);
    my $tarpath = $self->tarpath($basename);

    copy($file, $tarpath)
        or die "Copy failed $file $tarpath: $!\n";

    print "Wrote $tarpath from $file\n";
}

sub inject_from_http {
    my ($self, $url) = @_;

    my $basename = basename($url);

    my $tarpath = $self->tarpath($basename);

    my $response = HTTP::Tiny->new->mirror($url, $tarpath);
    unless ($response->{success}) {
        die "Cannot fetch $url($response->{status} $response->{reason})\n";
    }

    print "Wrote $tarpath from $url\n";
}

sub inject_from_git {
    my ($self, $repository, $branch) = @_;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $guard = pushd($tmpdir);

    _run("git clone $repository");

    if ($branch) {
        my $guard2 = pushd([<*>]->[0]);
        _run("git checkout $branch");
    }

    # The repository needs to contains META.json in repository.
    my $metafname = File::Spec->catfile([<*>]->[0], 'META.json');
    unless (-f $metafname) {
        die "$repository does not have a META.json\n";
    }

    my $meta = CPAN::Meta->load_file($metafname);

    my $name    = $meta->{name};
    my $version = $meta->{version};

    rename [<*>]->[0], "$name-$version";

    my $tarpath = $self->tarpath("$name-$version.tar.gz");

    unlink $tarpath if -f $tarpath;

    my $tar = Archive::Tar->new();
    my @files = $self->list_files($tmpdir);
    $tar->add_files(@files);
    $tar->write($tarpath, COMPRESS_GZIP);

    printf "Wrote $tarpath\n";
}

sub list_files {
    my ($self, $dir) = @_;

    my @files;
    find(
        {
            wanted => sub {
                my $rel = File::Spec->abs2rel($_, $dir);
                my $top = [File::Spec->splitdir($rel)]->[1];
                return if $top && $top eq '.git';
                return unless -f $_;
                push @files, $rel;
            },
            no_chdir => 1,
        }, $dir,
    );
    return @files;
}

sub _run {
    print "% @_\n";

    system(@_)
        == 0 or die "ABORT\n";
}

1;

