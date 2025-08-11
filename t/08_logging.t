use strict;
use warnings;

use Test::More;
use Test::Needs 'Test::Output';

use OrePAN2::Index   ();
use OrePAN2::Indexer ();

subtest 'test_default_logger', sub {

    # create new index
    my $index = OrePAN2::Index->new();

    # Add to index: X-0.01
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );

    # Add to index: X-0.02
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );

    # Add X-0.01 to index again -> expect logging
    Test::Output::stderr_like {
        $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' )
    }
    qr{\[INFO\] Not adding X in X/X/X/X-0.01.tar.gz},
        "got 'Not adding to index' via STDERR";

    my $tmpdir = Path::Tiny->tempdir( CLEANUP => 1 );

    my $orepan = OrePAN2::Indexer->new(
        directory => $tmpdir,
        simple    => 1,
    );

    Test::Output::stderr_like { $orepan->log->info("Testing") }
    qr{\[INFO\] Testing}, "got 'Testing' via STDERR";
};

done_testing;
