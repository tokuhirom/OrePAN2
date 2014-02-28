use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use File::stat;

my $dir = File::Temp::tempdir(CLEANUP => 1);

is system($^X, '-Ilib', "script/orepan2-inject", '--cache', 't/dat/Acme-Foo-0.01.tar.gz', $dir), 0;
ok -f "${dir}/modules/02packages.details.txt.gz";
my $tarpath = "${dir}/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz";
ok -f $tarpath;
my $mtime1 = stat($tarpath)->mtime;

sleep 1;
is system($^X, '-Ilib', "script/orepan2-inject", '--cache', 't/dat/Acme-Foo-0.01.tar.gz', $dir), 0;
my $mtime2 = stat($tarpath)->mtime;
is $mtime1, $mtime2, 'cached.';

done_testing;

