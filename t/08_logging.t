use strict;
use warnings;

use Test::More;
use Capture::Tiny (qw /capture/);
use Log::Any::Test;
use Log::Any;

use OrePAN2::Index ();
use OrePAN2::Indexer ();


subtest 'test_default_logger', sub {

    # create new index
    my $index = OrePAN2::Index->new();

    # Add to index: X-0.01
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );

    # Add to index: X-0.02
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );

    # Add X-0.01 to index again -> expect logging
    my ( undef, $stderr, undef ) = Capture::Tiny::capture {
        $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    };
    like $stderr, qr{\[INFO\] Not adding X in X/X/X/X-0.01.tar.gz},
        "got 'Not adding to index' via STDERR";
    like $stderr, qr{\[INFO\] Existing version 0.02 is greater than 0.01},
        "got 'Existing version greater than new' via STDERR";

    my $tmpdir = Path::Tiny->tempdir( CLEANUP => 1 );

    my $orepan = OrePAN2::Indexer->new(
        directory => $tmpdir,
        simple    => 1,
    );

    ( undef, $stderr, undef ) = Capture::Tiny::capture {
        $orepan->log->info("Testing");
    };
    like $stderr, qr{\[INFO\] Testing},
        "got 'Testing' via STDERR";

};

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
