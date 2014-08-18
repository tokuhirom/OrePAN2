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
use MetaCPAN::Client;

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
    my ($self, $source, $opts) = @_;
    local $self->{author} = uc($opts->{author} || $self->{author} || 'DUMMY');

    my $tarpath;
    if ($source =~ /(?:^git(?:\+\w+)?:|\.git(?:@.+)?$)/) { # steal from App::cpanminus::script
        # git URL has to end with .git when you need to use pin @ commit/tag/branch
        my ($uri, $commitish) = split /(?<=\.git)@/i, $source, 2;
        # git CLI doesn't support git+http:// etc.
        $uri =~ s/^git\+//;
        $tarpath = $self->inject_from_git($uri, $commitish);
    } elsif ($source =~ m{\Ahttps?://}) {
        $tarpath = $self->inject_from_http($source);
    } elsif (-f $source) {
        $tarpath = $self->inject_from_file($source);
    }
    elsif ( $source =~ m/^[\w_][\w0-9:_]+$/ ) {

        my $c = MetaCPAN::Client->new
            || die "Could not get MetaCPAN::Client";

        my $mod = $c->module($source)
            || die "Could not find $source";

        my $rel = $c->release( $mod->distribution )
            || die "Could not find distribution for $source";

        my $url = $rel->download_url
            || die "Could not find url for $source";

        $tarpath = $self->inject_from_http($url);
    }
    else {
        die "Unknown source: $source\n";
    }

    return File::Spec->abs2rel(File::Spec->rel2abs($tarpath), $self->directory);
}

sub tarpath {
    my ($self, $basename) = @_;

    my $author = uc($self->{author});
    my $tarpath = File::Spec->catfile($self->directory, 'authors', 'id',
        substr($author, 0, 1),
        substr($author, 0, 2),
        $author,
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

    return $tarpath;
}

sub inject_from_http {
    my ($self, $url) = @_;

    my $basename = basename($url);

    my $tarpath = $self->tarpath($basename);

    my $response = HTTP::Tiny->new->mirror($url, $tarpath);
    unless ($response->{success}) {
        die "Cannot fetch $url($response->{status} $response->{reason})\n";
    }

    return $tarpath;
}

sub inject_from_git {
    my ($self, $repository, $branch) = @_;

    my $tmpdir = tempdir(CLEANUP => 1);

    my ($basename, $tar) = do {
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

        rename([<*>]->[0], "$name-$version")
            or die $!;

        my $tmp_path = File::Spec->catfile($tmpdir,
        );

        my $tar = Archive::Tar->new();
        my @files = $self->list_files($tmpdir);
        $tar->add_files(@files);

        ("$name-$version.tar.gz", $tar);
    };

    my $tarpath = $self->tarpath($basename);
    # Must be same partition.
    my $tmp_tarpath = File::Temp::mktemp("${tarpath}.XXXXXX");
    $tar->write($tmp_tarpath, COMPRESS_GZIP);
    unlink $tarpath if -f $tarpath;
    rename($tmp_tarpath => $tarpath)
        or die $!;

    return $tarpath;
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

