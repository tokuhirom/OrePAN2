use strict;
use warnings;
use utf8;
use Test::More;
use IO::Uncompress::Gunzip ();
use OrePAN2::Index         ();
use Path::Tiny             ();

subtest 'load, lookup' => sub {
    for my $file (
        't/dat/02.packages.details.txt',
        't/dat/02.packages.details.txt.gz'
    ) {
        subtest $file => sub {
            my $index = OrePAN2::Index->new();
            $index->load($file);
            subtest 'The package has undef version', sub {
                my ( $ver, $path ) = $index->lookup('A_Third_Package');
                is $ver,  undef;
                is $path, 'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz';
            };
            subtest 'has a version', sub {
                my ( $ver, $path ) = $index->lookup('AAAA::Crypt::DH');
                is $ver,  '0.04';
                is $path, 'B/BI/BINGOS/AAAA-Crypt-DH-0.04.tar.gz';
            };
        };
    }
};

subtest 'add_index', sub {

    # Given create new index
    my $index = OrePAN2::Index->new;

    # And index X-0.01
    $index->add_index( 'X', 0.01, 'X/X/X/X-0.01.tar.gz' );

    # When index X-0.02
    $index->add_index( 'X', 0.02, 'X/X/X/X-0.02.tar.gz' );

    # Then, X-0.02 was indexed
    is [ $index->lookup('X') ]->[1], 'X/X/X/X-0.02.tar.gz';
};

subtest 'delete' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');
    ok [ $index->lookup('A_Third_Package') ]->[1],
        'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz';
    $index->delete_index('A_Third_Package');
    is [ $index->lookup('A_Third_Package') ]->[1], undef;
};

subtest 'as_string' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');
    like $index->as_string, qr{A_Third_Package};
};

subtest 'as_gzip' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $gzip = Path::Tiny->tempfile( DIR => 't', SUFFIX => '.gz' );

    $index->as_gzip("$gzip");

    my $copy = OrePAN2::Index->new;
    $copy->load("$gzip");
    is($copy->as_string, $index->as_string, "Got the same contents");
};

subtest 'as_gzip forwards options to as_string' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $gzip = Path::Tiny->tempfile( DIR => 't', SUFFIX => '.gz' );
    $index->as_gzip( "$gzip", { simple => 1 } );

    my $decompressed;
    IO::Uncompress::Gunzip::gunzip( "$gzip" => \$decompressed )
        or die
        "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
    is $decompressed, $index->as_string( { simple => 1 } ),
        '{ simple => 1 } was forwarded to as_string';
};

subtest 'as_gzip dies when destination directory is missing' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $tempdir  = Path::Tiny->tempdir;
    my $bad_path = $tempdir->child( 'does-not-exist', 'foo.gz' );
    eval { $index->as_gzip("$bad_path") };
    like $@, qr{\S}, 'as_gzip propagates an error from the file write';
};

done_testing;

