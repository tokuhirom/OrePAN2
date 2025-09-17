use strict;
use warnings;

use Test::More;
use Test::Needs 'Log::Any::Test', 'Log::Any';

use OrePAN2::Index   ();
use OrePAN2::Indexer ();
use Path::Tiny       ();

subtest 'test_log_any', sub {
    my $log = Log::Any->get_logger();

    my $index = OrePAN2::Index->new( log => $log );

    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    $log->contains_ok(
        qr{Not adding X in X/X/X/X-0.01.tar.gz},
        "got 'Not adding to index' via Log::Any"
    );
    $log->contains_ok(
        qr{Existing version 0.02 is greater than 0.01},
        "got 'Existing version greater than new' via Log::Any"
    );

    my $tmpdir = Path::Tiny->tempdir( CLEANUP => 1 );

    my $orepan = OrePAN2::Indexer->new(
        directory => $tmpdir,
        simple    => 1,
        log       => $log,
    );

    $orepan->log->info("Testing");
    $log->contains_ok(
        qr{Testing},
        "got 'Testing' via Log::Any"
    );
};

done_testing;