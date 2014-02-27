use strict;
use warnings;
use utf8;
use Test::More;

use OrePAN2::Repository;
use File::Temp;

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $repo = OrePAN2::Repository->new(directory => $tmpdir);
$repo->inject('t/dat/Acme-Foo-0.01.tar.gz');
$repo->make_index;
$repo->gc();

ok -f "$tmpdir/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz";
ok -f "$tmpdir/modules/02packages.details.txt.gz";

done_testing;

