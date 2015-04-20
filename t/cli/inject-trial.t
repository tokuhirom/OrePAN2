use strict;
use warnings;

use File::Temp;
use LWP::UserAgent;
use PAUSE::Packages;
use Path::Tiny;
use Test::More;
use Test::RequiresInternet ( 'cpan.metacpan.org' => 80 );
use URI::FromHash qw( uri );
use t::Util;

_test_trial(0);

#_test_trial(1);

sub _test_trial {
    my $allow_dev = shift;
    my $dir       = File::Temp::tempdir( CLEANUP => 1 );
    my $archive   = 'Acme-Foo-0.01_15.tar.gz';
    my $path      = path('t/dat/')->child($archive);

    my @args = ( '-Ilib', 'script/orepan2-inject', $path, $dir );
    is( system( $^X, @args ), 0, 'no errors on inject' );

    my $injected
        = path($dir)->child( 'authors', 'id', 'D', 'DU', 'DUMMY', $archive );

    ok( -f $injected, 'Generated tarball exists' );

    my $pkgs_path
        = path($dir)->child( 'modules', '02packages.details.txt.gz' );

    my $pp = PAUSE::Packages->new(
        url => 'file://' . $pkgs_path,
        ua  => LWP::UserAgent->new,
    );

    my $release = $pp->release('Acme-Foo');
    if ($allow_dev) {
        ok( $release, 'dev release indexed' );
    }
    else {
        ok( !$release, 'dev release not indexed' );
    }
}

done_testing;
