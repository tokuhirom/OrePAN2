use strict;
use warnings;
use utf8;
use Test::More;
use Test::More;
use t::Util;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Copy qw(copy);

use OrePAN2::Injector;

subtest 'gz' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author => 'MIYAGAWA',
    );
    $injector->inject('t/dat/Acme-YakiniQ-0.01.tar.gz');
    ok -f "$tmpdir/authors/id/M/MI/MIYAGAWA/Acme-YakiniQ-0.01.tar.gz";
};

subtest 'author name must be upper case' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author => 'upper',
    );
    $injector->inject('t/dat/Acme-Foo-0.01.tar.gz');
    ok -f "$tmpdir/authors/id/U/UP/UPPER/Acme-Foo-0.01.tar.gz";
};

done_testing;
