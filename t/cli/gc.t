use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use File::Temp;

my $dir = File::Temp::tempdir(CLEANUP => 1);
is system($^X, '-Ilib', 'script/orepan2-inject', '--text', 't/dat/Acme-Foo-0.01.tar.gz', $dir), 0;

ok -f "${dir}/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz", 'Generated tar ball';

# truncate file.
open my $fh, '>', "${dir}/modules/02packages.details.txt"
    or die $!;
close $fh;

is system($^X, '-Ilib', 'script/orepan2-gc', '--text', $dir), 0;

ok((!-f "${dir}/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz"), 'removed!');

done_testing;

