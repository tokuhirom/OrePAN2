use strict;
use warnings;
use utf8;

use Test::More;
use Test::RequiresInternet( 'api.metacpan.org' => 80 );
use File::Temp qw(tempdir);
use MetaCPAN::Client;

use OrePAN2::Indexer;
use OrePAN2::Injector;

subtest 'use MetaCPAN' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $mcpan  = MetaCPAN::Client->new;
    my $module = $mcpan->module('OrePAN2');

    my $release = $mcpan->release( $module->distribution );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author    => $release->author,
    );
    $injector->inject('OrePAN2');

    my $path = $release->download_url;
    $path =~ s{\A.*/authors/}{};

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

sub inject_and_index {
    my $dir     = shift;
    my $archive = shift;

    my $injector = OrePAN2::Injector->new( directory => $dir, );
    $injector->inject($archive);
    my $orepan = OrePAN2::Indexer->new( directory => $dir, metacpan => 1 );
    return $orepan->make_index;
}

done_testing;
