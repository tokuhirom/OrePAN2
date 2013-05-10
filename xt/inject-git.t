use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);

use OrePAN2::CLI::Inject;

no warnings 'redefine';
*OrePAN2::CLI::Inject::pod2usage = sub { die };

my @specs = (
    [
        'git@github.com:tokuhirom/Acme-Foo.git',
        "authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz"
    ],
    [
        'git@github.com:tokuhirom/Acme-Foo.git@master',
        "authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz"
    ],
);

for my $spec (@specs) {
    my $tmpdir = tempdir( CLEANUP => 1 );
    local @ARGV = ($spec->[0], $tmpdir);
    OrePAN2::CLI::Inject->new->run();
    ok(-f "$tmpdir/@{[ $spec->[1] ]}");
}

subtest 'no index' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    local @ARGV = ('--no-generate-index', 't/dat/Acme-Foo-0.01.tar.gz', $tmpdir);
    OrePAN2::CLI::Inject->new->run();
    ok(!-f "$tmpdir/modules/02packages.details.txt.gz");
};

done_testing;

