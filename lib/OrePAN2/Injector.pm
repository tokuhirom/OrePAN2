package OrePAN2::Injector;

use strict;
use warnings;
use utf8;

use Archive::Extract ();
use Archive::Tar     qw( COMPRESS_GZIP );
use CPAN::Meta       ();
use File::Basename   qw( basename dirname );
use File::Copy       qw( copy );
use File::Find       qw( find );
use File::Path       qw( mkpath );
use File::Spec       ();
use File::Temp       qw( tempdir );
use File::pushd      qw( pushd );
use HTTP::Tiny       ();
use MetaCPAN::Client ();

sub new {
    my $class = shift;
    my %args  = @_ == 1 ? %{ $_[0] } : @_;
    unless ( exists $args{directory} ) {
        Carp::croak("Missing directory");
    }
    bless {
        author => 'DUMMY',
        %args
    }, $class;
}

sub directory { shift->{directory} }

sub inject {
    my ( $self, $source, $opts ) = @_;
    local $self->{author}
        = $opts->{author} || $self->{author} || 'DUMMY';
    local $self->{author_subdir} = $opts->{author_subdir} || q{};

    my $tarpath;
    if ( $source =~ /(?:^git(?:\+\w+)?:|\.git(?:@.+)?$)/ )
    {    # steal from App::cpanminus::script
         # git URL has to end with .git when you need to use pin @ commit/tag/branch
        my ( $uri, $commitish ) = split /(?<=\.git)@/i, $source, 2;

        # git CLI doesn't support git+http:// etc.
        $uri =~ s/^git\+//;
        $tarpath = $self->inject_from_git( $uri, $commitish );
    }
    elsif ( $source =~ m{\Ahttps?://} ) {
        $tarpath = $self->inject_from_http($source);
    }
    elsif ( -f $source ) {
        $tarpath = $self->inject_from_file($source);
    }
    elsif ( $source =~ m/^[\w_][\w0-9:_]+$/ ) {

        my $c = MetaCPAN::Client->new( version => 'v1' )
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

    return File::Spec->abs2rel(
        File::Spec->rel2abs($tarpath),
        $self->directory
    );
}

sub tarpath {
    my ( $self, $basename ) = @_;

    my $author  = uc( $self->{author} );
    my $tarpath = File::Spec->catfile(
        $self->directory, 'authors', 'id',
        substr( $author, 0, 1 ),
        substr( $author, 0, 2 ),
        $author,
        $self->{author_subdir},
        $basename
    );
    mkpath( dirname($tarpath) );

    return $tarpath;
}

sub _detect_author {
    my ( $self, $source, $archive ) = @_;
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $ae     = Archive::Extract->new( archive => $archive );
    $ae->extract( to => $tmpdir );
    my $guard = pushd( glob("$tmpdir/*") );
    $self->{author}->($source);
}

sub inject_from_file {
    my ( $self, $file ) = @_;

    local $self->{author} = $self->_detect_author( $file, $file )
        if ref $self->{author} eq "CODE";
    my $basename = basename($file);
    my $tarpath  = $self->tarpath($basename);

    copy( $file, $tarpath )
        or die "Copy failed $file $tarpath: $!\n";

    return $tarpath;
}

sub inject_from_http {
    my ( $self, $url ) = @_;

    # If $self->{author} is not a code reference,
    # then $tarpath is fixed before http request
    # and HTTP::Tiny->mirror works correctly.
    # So we treat that case first.
    if ( ref $self->{author} ne "CODE" ) {
        my $basename = basename($url);
        my $tarpath  = $self->tarpath($basename);
        my $response = HTTP::Tiny->new->mirror( $url, $tarpath );
        unless ( $response->{success} ) {
            die
                "Cannot fetch $url($response->{status} $response->{reason})\n";
        }
        return $tarpath;
    }

    my $tmpdir   = tempdir( CLEANUP => 1 );
    my $tmpfile  = "$tmpdir/tmp.tar.gz";
    my $response = HTTP::Tiny->new->mirror( $url, $tmpfile );
    unless ( $response->{success} ) {
        die "Cannot fetch $url($response->{status} $response->{reason})\n";
    }

    my $basename = basename($url);
    local $self->{author} = $self->_detect_author( $url, $tmpfile );
    my $tarpath = $self->tarpath($basename);
    copy( $tmpfile, $tarpath )
        or die "Copy failed $tmpfile $tarpath: $!\n";

    my $mtime = ( stat $tmpfile )[9];
    utime $mtime, $mtime, $tarpath;

    return $tarpath;
}

sub inject_from_git {
    my ( $self, $repository, $branch ) = @_;

    my $tmpdir = tempdir( CLEANUP => 1 );

    my ( $basename, $tar, $author ) = do {
        my $guard = pushd($tmpdir);

        _run("git clone $repository");

        if ($branch) {
            my $guard2 = pushd( [<*>]->[0] );
            _run("git checkout $branch");
        }

        my $author;
        if ( ref $self->{author} eq "CODE" ) {
            my $guard2 = pushd( [<*>]->[0] );
            $author = $self->{author}->($repository);
        }

        # The repository needs to contains META.json in repository.
        my $metafname = File::Spec->catfile( [<*>]->[0], 'META.json' );
        unless ( -f $metafname ) {
            die "$repository does not have a META.json\n";
        }

        my $meta = CPAN::Meta->load_file($metafname);

        my $name    = $meta->{name};
        my $version = $meta->{version};

        rename( [<*>]->[0], "$name-$version" )
            or die $!;

        my $tmp_path = File::Spec->catfile(
            $tmpdir,
        );

        my $tar   = Archive::Tar->new();
        my @files = $self->list_files($tmpdir);
        $tar->add_files(@files);

        ( "$name-$version.tar.gz", $tar, $author );
    };

    local $self->{author} = $author if $author;
    my $tarpath = $self->tarpath($basename);

    # Must be same partition.
    my $tmp_tarpath = File::Temp::mktemp("${tarpath}.XXXXXX");
    $tar->write( $tmp_tarpath, COMPRESS_GZIP );
    unlink $tarpath if -f $tarpath;
    rename( $tmp_tarpath => $tarpath )
        or die $!;

    return $tarpath;
}

sub list_files {
    my ( $self, $dir ) = @_;

    my @files;
    find(
        {
            wanted => sub {
                my $rel = File::Spec->abs2rel( $_, $dir );
                my $top = [ File::Spec->splitdir($rel) ]->[1];
                return if $top && $top eq '.git';
                return unless -f $_;
                push @files, $rel;
            },
            no_chdir => 1,
        },
        $dir,
    );
    return @files;
}

sub _run {
    print "% @_\n";

    system(@_) == 0 or die "ABORT\n";
}

1;

__END__

=encoding utf-8

=for stopwords DarkPAN orepan2-inject orepan2-indexer darkpan OrePAN1 OrePAN

=head1 NAME

OrePAN2::Injector - Inject a distribution to your DarkPAN

=head1 SYNOPSIS

    use OrePAN2::Injector;

    my $injector = OrePAN2::Injector->new(directory => '/path/to/darkpan');

    $injector->inject(
        'http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz',
        { author => 'MAHITO' },
    );

=head1 DESCRIPTION

OrePAN2::Injector allows you to inject a distribution into your DarkPAN.

=head1 METHODS

=head3 C<< my $injector = OrePAN2::Injector->new(%attr) >>

Constructor. Here C<%attr> might be:

=over 4

=item * directory

Your DarkPAN directory path. This is required.

=item * author

Default author of distributions.
If you omit this, then C<DUMMY> will be used.

B<BETA>: As of OrePAN2 0.37,
the author attribute accepts a code reference, so that
you can calculate author whenever injecting distributions:

    my $author_cb = sub {
        my $source = shift;
        $source =~ m{authors/id/./../([^/]+)} ? $1 : "DUMMY";
    };

    my $injector = OrePAN2::Injector->new(
        directory => '/path/to/darkpan',
        author => $author_cb,
    );

    $injector->inject(
        'http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz'
    );
    #=> Acme-Hoge-0.03 will be indexed with author MAHITO

Note that the code reference C<$author_cb> will be executed
under the following circumstances:

    * the first argument is the $source argument to the inject method
    * the working directory of it is the top level of the distribution in question

=item * author_subdir

This is an optional attribute.  If present it means that directory elements
will be created following the author.  This can be useful, for instance,
if you want to make your DarkPAN have paths that exactly match the paths
in CPAN.  Sometimes CPAN paths look something like the following:

    authors/id/<author>/modules/...

In the above case you can pass 'modules' as the value for author_subdir so
that the path OrePAN2 creates looks like the above path.

=back

=head3 C<< $injector->inject($source, \%option) >>

Inject C<$source> to your DarkPAN. Here C<$source> is one of the following:

=over 4

=item * local archive file

eg: /path/to/Text-TestBase-0.10.tar.gz

=item * HTTP url

eg: http://cpan.metacpan.org/authors/id/T/TO/TOKUHIROM/Text-TestBase-0.10.tar.gz

=item * git repository

eg: git://github.com/tokuhirom/Text-TestBase.git@master

Note that you need to set up git repository as a installable git repo,
that is, you need to put a META.json in your repository.

If you are using L<Minilla> or L<Milla>, your repository is already ready to install.

Supports the following URL types:

    git+file://path/to/repo.git
    git://github.com/plack/Plack.git@1.0000        # tag
    git://github.com/plack/Plack.git@devel         # branch

They are compatible with L<cpanm>.

=item * module name

eg: Data::Dumper

=back

C<\%option> might be:

=over 4

=item * author

Author of the distribution. This overrides C<new>'s author attribute.

=back

=head1 SEE ALSO

L<orepan2-inject>

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut
