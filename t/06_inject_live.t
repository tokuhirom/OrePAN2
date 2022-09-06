use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More;
use Test::RequiresInternet( 'api.metacpan.org' => 80 );
use File::Temp qw(tempdir);
use MetaCPAN::Client;
use OrePAN2::Indexer;
use OrePAN2::Injector;
use Local::Util qw( slurp );

sub inject_module {
    my $name   = shift;
    my $tmpdir = shift;
    my $mcpan  = MetaCPAN::Client->new( version => 'v1' );
    my $module = $mcpan->module($name);

    my $release  = $mcpan->release( $module->distribution );
    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author    => $release->author,
    );
    $injector->inject($name);
    return $release;
}

subtest 'case insensitive sorting' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    inject_module( $_, $tmpdir ) for ( 'autodie', 'fatfinger' );

    my $orepan = OrePAN2::Indexer->new( directory => $tmpdir, metacpan => 1 );
    $orepan->make_index( no_compress => 1 );

    my $details = slurp("$tmpdir/modules/02packages.details.txt");
    my @rows    = split "\n", $details;
    ok( $rows[-1] =~ m{\Afatfinger}, 'fatfinger is last' );
    ok( $rows[-2] =~ m{\AFatal},     'Fatal precedes fatfinger' );
};

subtest 'use MetaCPAN' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $release = inject_module( 'OrePAN2', $tmpdir );

    my $path = url2path( $release->download_url );

    ok -f "$tmpdir/authors/$path", 'path exists';

    my $orepan = OrePAN2::Indexer->new( directory => $tmpdir, metacpan => 1 );
    $orepan->make_index( no_compress => 1 );

    ok(
        exists $orepan->_metacpan_lookup->{archive}->{ $release->archive },
        'archive found by MetaCPAN'
    );

    my $provides = $orepan->_metacpan_lookup->{release}->{ $release->name };
    ok( $provides, 'release found by MetaCPAN' );

    is(
        $provides->{OrePAN2}, $release->version,
        'correct version reported by provides'
    );
};

subtest 'MetaCPAN lookup works in chunks' => sub {
    my $tmpdir  = tempdir( CLEANUP => 1 );
    my @modules = qw( OrePAN2 autodie );
    my %release;

    for my $module (@modules) {
        my $release = inject_module( $module, $tmpdir );
        $release{$module}{$_} = $release->$_
            for qw( download_url archive name );
    }

    my $orepan = OrePAN2::Indexer->new(
        directory            => $tmpdir,
        metacpan             => 1,
        metacpan_lookup_size => 1,
    );

    $orepan->do_metacpan_lookup(
        [ map url2path( $release{$_}{download_url} ), @modules ] );

    for my $module (@modules) {
        ok(
            exists $orepan->_metacpan_lookup->{archive}
                { $release{$module}{archive} },
            "%module archive found by MetaCPAN"
        );
        ok(
            $orepan->_metacpan_lookup->{release}{ $release{$module}{name} },
            "$module release found by MetaCPAN"
        );
    }
};

subtest 'Upgrade undef versions' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    # Since we are now sorting the files by modification time, order of
    # injection does not matter.  If someone is downgrading a module, they
    # should delete the later module from the darkpan and then inject the
    # module they are downgrading to.  In this case we're injecting in the
    # wrong order, but the newer archive will take precedence.

    inject_and_index(
        $tmpdir,
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz'
    );

    my $index = inject_and_index(
        $tmpdir,
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.31.tar.gz'
    );
    my $latest = 'OrePAN2-0.32.tar.gz';

    foreach my $pkg ( 'OrePAN2', 'OrePAN2::Indexer' ) {
        like(
            $index->{index}->{$pkg}->[1],
            qr{$latest}, "$pkg is in $latest"
        );
    }
};

subtest 'code reference author with inject from http works' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $author = sub {
        my $source = shift;
        if ( $source =~ m{authors/id/./../([^/]+)} ) {
            return $1;
        }
        else {
            die "unexpected";
        }
    };
    my $injector = OrePAN2::Injector->new( directory => $tmpdir );
    $injector->inject(
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz',
        { author => $author },
    );
    ok -f "$tmpdir/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz",
        "detect author by url";
};

sub inject_and_index {
    my $dir     = shift;
    my $archive = shift;

    my $injector = OrePAN2::Injector->new( directory => $dir, );
    $injector->inject($archive);
    my $orepan = OrePAN2::Indexer->new( directory => $dir, metacpan => 1 );
    return $orepan->make_index;
}

sub url2path {
    my ($url) = @_;
    ( my $path = $url ) =~ s{\A.*/authors/}{};
    return $path;
}

done_testing;
