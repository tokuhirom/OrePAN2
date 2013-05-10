use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Copy qw(copy);

use OrePAN2::Indexer;
use OrePAN2::Injector;

my $tmpdir = tempdir(CLEANUP => 1);

mkpath "$tmpdir/authors/id/M/MI/MIYAGAWA/";

my $injector = OrePAN2::Injector->new(directory => $tmpdir);
$injector->inject('t/dat/Acme-Foo-0.01.tar.gz');

my $indexer = OrePAN2::Indexer->new(
    directory => $tmpdir,
);
$indexer->make_index();

my $content = slurp_gz "$tmpdir/modules/02packages.details.txt.gz";
note $content;
like $content, qr{Acme::Foo\s+0.01\s+D/DU/DUMMY/Acme-Foo-0.01.tar.gz};
unlike $content, qr{gaaa::foo};

done_testing;

