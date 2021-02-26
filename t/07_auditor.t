use strict;
use warnings;

use Capture::Tiny qw( capture_stdout );
use FindBin          ();
use OrePAN2::Auditor ();
use Test::More;

my $auditor = OrePAN2::Auditor->new(
    cpan    => "file://$FindBin::Bin/dat/auditor/cpan/02packages.details.txt",
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

{
    my $module = $auditor->cpan_module('AAA::Demo');
    isa_ok(
        $module,
        'Parse::CPAN::Packages::Fast::Package'
    );
    is( $module->package, 'AAA::Demo', 'AAA::Demo package' );

    # Parse::CPAN::Packages::Fast::Package is just splitting the lines in
    # 02packages, so it returns "undef" as a string.
    is( $module->version, 'undef', 'AAA::Demo version' );
}

{
    my $module = $auditor->darkpan_module('Foo::Bar');
    isa_ok(
        $module,
        'Parse::CPAN::Packages::Fast::Package'
    );
    is( $module->package, 'Foo::Bar', 'Foo::Bar package' );
    is( $module->version, '1.0', 'Foo::Bar version' );
}

my $outdated_releases = capture_stdout( sub { $auditor->_outdated_releases } );
my $expected = <<'EOF';
AAAA-Crypt-DH-0.02 => AAAA-Crypt-DH-0.04
https://metacpan.org/changes/distribution/AAAA-Crypt-DH

EOF

is( $outdated_releases, $expected, 'outdated_releases' );

my $runner = OrePAN2::Auditor->new(
    cpan    => "file://$FindBin::Bin/dat/auditor/cpan/02packages.details.txt",
    darkpan => 't/dat/auditor/darkpan/02packages.details.txt',
    show => 'outdated-releases',
);

my $outdated_via_run = capture_stdout( sub { $runner->run } );
is( $outdated_via_run, $expected, 'outdated_releases via run()' );

done_testing;
