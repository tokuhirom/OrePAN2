use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Copy qw(copy);

use OrePAN2::Indexer;

subtest 'gz' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    mkpath "$tmpdir/authors/id/M/MI/MIYAGAWA/";

    copy 't/dat/Acme-YakiniQ-0.01.tar.gz', "$tmpdir/authors/id/M/MI/MIYAGAWA";

    my $orepan = OrePAN2::Indexer->new(
        directory => $tmpdir,
    );
    $orepan->make_index();

    my $content = slurp_gz "$tmpdir/modules/02packages.details.txt.gz";
    note $content;
    like $content, qr{Acme::YakiniQ\s+0.01\s+M/MI/MIYAGAWA/Acme-YakiniQ-0.01.tar.gz};
};

subtest 'txt' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    mkpath "$tmpdir/authors/id/M/MI/MIYAGAWA/";

    copy 't/dat/Acme-YakiniQ-0.01.tar.gz', "$tmpdir/authors/id/M/MI/MIYAGAWA";

    my $orepan = OrePAN2::Indexer->new(
        directory => $tmpdir,
    );
    $orepan->make_index(no_compress => 1);

    my $content = slurp "$tmpdir/modules/02packages.details.txt";
    note $content;
    like $content, qr{Acme::YakiniQ\s+0.01\s+M/MI/MIYAGAWA/Acme-YakiniQ-0.01.tar.gz};
};

done_testing;

