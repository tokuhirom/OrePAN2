use strict;
use warnings;
use utf8;

use Test::More;
use t::Util;

use OrePAN2::Repository;
use File::Temp;

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $repo = OrePAN2::Repository->new(directory => $tmpdir, simple => 1);
$repo->inject('t/dat/Acme-Foo-0.01.tar.gz');
$repo->make_index();

my $content = slurp_gz "$tmpdir/modules/02packages.details.txt.gz";
unlike( $content, qr{Last\-Updated}, 'simple format' );
$repo->gc();

ok -f "$tmpdir/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz";
ok -f "$tmpdir/modules/02packages.details.txt.gz";
ok !-f "$tmpdir/modules/02packages.details.txt";

done_testing;

