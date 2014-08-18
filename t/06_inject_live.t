use strict;
use warnings;
use utf8;
use Test::More;
use Test::RequiresInternet( 'api.metacpan.org' => 80 );
use File::Temp qw(tempdir);
use MetaCPAN::Client;

use OrePAN2::Injector;

subtest 'use MetaCPAN' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    my $mcpan = MetaCPAN::Client->new;
    my $module = $mcpan->module('OrePAN2');

    my $release = $mcpan->release( $module->distribution );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author => $release->author,
    );
    $injector->inject('OrePAN2');

    my $path = $release->download_url;
    $path =~ s{\A.*/authors/}{};

    ok -f "$tmpdir/authors/$path";
};

done_testing;
