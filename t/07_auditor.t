use strict;
use warnings;

use FindBin;
use OrePAN2::Auditor;
use Path::Class qw( file );
use Test::More;

subtest 'audit packages' => sub {
    my $auditor = OrePAN2::Auditor->new(
        cpan =>
            "file://$FindBin::Bin/dat/auditor/cpan/02packages.details.txt",
        darkpan => 't/dat/auditor/darkpan/02packages.details.txt'
    );

    is_deeply(
        $auditor->darkpan_modules, [ 'AAAA::Crypt::DH', 'Foo::Bar', ],
        'darkpan modules'
    );
    is_deeply(
        $auditor->cpan_modules,
        [ 'AAA::Demo', 'AAA::eBay', 'AAAA::Crypt::DH', ],
        'cpan modules'
    );

    is_deeply(
        $auditor->darkpan_only_modules, [ 'Foo::Bar', ],
        'modules unique to darkpan'
    );

    is_deeply(
        $auditor->cpan_only_modules, [ 'AAA::Demo', 'AAA::eBay', ],
        'modules unique to cpan'
    );

    is_deeply(
        $auditor->outdated_modules, ['AAAA::Crypt::DH'],
        'modules unique to cpan'
    );
};

done_testing;
