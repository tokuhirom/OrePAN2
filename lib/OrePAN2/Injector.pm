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
use MetaCPAN::API;

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

    if ($source =~ /(?:^git(?:\+\w+)?:|\.git(?:@.+)?$)/) { # steal from App::cpanminus::script
        # git URL has to end with .git when you need to use pin @ commit/tag/branch
        my ($uri, $commitish) = split /(?<=\.git)@/i, $source, 2;
        # git CLI doesn't support git+http:// etc.
        $uri =~ s/^git\+//;
        $self->inject_from_git($uri, $commitish);
    } elsif ($source =~ m{\Ahttps?://}) {
        $self->inject_from_http($source);
    } elsif (-f $source) {
        $self->inject_from_file($source);
    }
    elsif ( $source =~ m/^[\w_][\w0-9:_]+$/ ) {

        my $c = MetaCPAN::API->new
            || die "Could not get MetaCPAN API";

        my $mod = $c->module($source)
            || die "Could not find $source";

        my $rel = $c->release( distribution => $mod->{distribution} )
            || die "Could not find distribution for $source";

        my $url = $rel->{download_url}
            || die "Could not find url for $source";

        $self->inject_from_http($url);
    }
    else {
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

    my $tmp_tarpath = do {
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

        my $tmp_path = File::Spec->catfile($tmpdir, "$name-$version.tar.gz");

        my $tar = Archive::Tar->new();
        my @files = $self->list_files($tmpdir);
        $tar->add_files(@files);
        $tar->write($tmp_path, COMPRESS_GZIP);

        $tmp_path;
    };

    my $tarpath = $self->tarpath(basename $tmp_tarpath);
    unlink $tarpath if -f $tarpath;
    rename $tmp_tarpath => $tarpath;

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

