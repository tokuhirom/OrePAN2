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
    my $module = $mcpan->module( 'OrePAN2' );

    my $release = $mcpan->release( $module->distribution );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author    => $release->author,
    );
    $injector->inject( 'OrePAN2' );

    my $path = $release->download_url;
    $path =~ s{\A.*/authors/}{};

    ok -f "$tmpdir/authors/$path", 'path exists';

    my $orepan = OrePAN2::Indexer->new( directory => $tmpdir, metacpan => 1 );
    $orepan->make_index( no_compress => 1 );

    ok( exists $orepan->_metacpan_lookup->{archive}->{ $release->archive },
        'archive found by MetaCPAN' );

    my $provides = $orepan->_metacpan_lookup->{release}->{ $release->name };
    ok( $provides, 'release found by MetaCPAN' );

    is( $provides->{OrePAN2}, $release->version,
        'correct version reported by provides' );
};

done_testing;
