use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More;
use File::Touch qw( touch );
use Local::Util qw( slurp_gz );
use Path::Tiny  qw();

use OrePAN2::Repository ();

{
    my ( $repo, $tmpdir ) = make_repo();
    my $content = slurp_gz("$tmpdir/modules/02packages.details.txt.gz");
    unlike( $content, qr{Last\-Updated}, 'simple format' );

    $repo->gc();
    test_repo($tmpdir);
}

{
    my ( $repo, $tmpdir ) = make_repo();

    $repo->gc( sub { my $file = shift; unlink $file; diag "unlinked $file"; }
    );
    test_repo($tmpdir);
}

sub make_repo {
    my $tmpdir = Path::Tiny->tempdir( CLEANUP => 1 );

    my $repo = OrePAN2::Repository->new( directory => $tmpdir, simple => 1 );
    $repo->inject('t/dat/Acme-Foo-0.01.tar.gz');
    $repo->make_index();
    touch("$tmpdir/authors/id/D/DU/DUMMY/foo.tar.gz");

    return ( $repo, $tmpdir );
}

sub test_repo {
    my $tmpdir = shift;

    ok -f "$tmpdir/authors/id/D/DU/DUMMY/Acme-Foo-0.01.tar.gz",
        'Acme-Foo-0.01.tar.gz exists';
    ok !-f "$tmpdir/authors/id/D/DU/DUMMY/foo.tar.gz",
        'foo.tar.gz does not exist';
    ok -f "$tmpdir/modules/02packages.details.txt.gz",
        '02packages.details.txt.gz exists';
    ok !-f "$tmpdir/modules/02packages.details.txt",
        '02packages.details.txt does not exist';
}

done_testing;

