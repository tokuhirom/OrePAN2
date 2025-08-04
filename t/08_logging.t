use strict;
use warnings;

use Test::More;
use OrePAN2::Index ();

subtest 'add_index_default_logger', sub {

    plan skip_all => 'requires Capture::Tiny'
        unless eval {
        use Capture::Tiny ':all';
        1;
        };

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
        'INFO: Not adding to index (via STDERR)';
    like $stderr, qr{\[INFO\] Existing version 0.02 is greater than 0.01},
        'INFO: Existing version greater than new  (via STDERR)';
};

subtest 'add_index_log_any', sub {

    plan skip_all => 'requires Log::Any and Log::Any::Test'
        unless eval {
        require Log::Any;
        require Log::Any::Test;
        1;
        };

    Log::Any->import;
    Log::Any::Test->import;

    my $log = Log::Any->get_logger();

    my $index = OrePAN2::Index->new( log => $log );

    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    $log->contains_ok(
        qr{Not adding X in X/X/X/X-0.01.tar.gz},
        "INFO: Not adding to index (via Log::Any)"
    );
    $log->contains_ok(
        qr{Existing version 0.02 is greater than 0.01},
        "INFO: Existing version greater than new (via Log::Any)"
    );
};

subtest 'add_index_mojo_log', sub {

    plan skip_all => 'requires Mojo::Log'
        unless eval {
        require Mojo::Log;
        1;
        };

    Mojo::Log->import;

    my $log      = Mojo::Log->new;
    my $messages = $log->capture();

    my $index = OrePAN2::Index->new( log => $log );
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );
    like $messages->[-2], qr{\[info\] Not adding X in X/X/X/X-0.01.tar.gz},
        'INFO: Not adding to index (via Mojo::Log)';
    like $messages->[-1],
        qr{\[info\] Existing version 0.02 is greater than 0.01},
        'INFO: Existing version greater than new  (via Mojo::Log)';
};

done_testing;
