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

subtest 'merge' => sub {
    subtest 'higher version wins with no protect_author' => sub {
        my $index = OrePAN2::Index->new;
        $index->add_index( 'Foo::Bar', '0.01', 'D/DU/DUMMY/Foo-Bar-0.01.tar.gz' );

        my $other = OrePAN2::Index->new;
        $other->add_index( 'Foo::Bar', '2.00', 'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz' );

        $index->merge($other);
        is [ $index->lookup('Foo::Bar') ]->[1],
            'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz';
    };

    subtest 'protect_author keeps the lower version' => sub {
        my $index = OrePAN2::Index->new;
        $index->add_index( 'Foo::Bar', '0.01', 'D/DU/DUMMY/Foo-Bar-0.01.tar.gz' );

        my $other = OrePAN2::Index->new;
        $other->add_index( 'Foo::Bar', '2.00', 'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz' );

        $index->merge( $other, protect_author => ['dummy'] );
        is [ $index->lookup('Foo::Bar') ]->[1],
            'D/DU/DUMMY/Foo-Bar-0.01.tar.gz',
            'matches case-insensitively';
    };

    subtest 'protection is per-package, not per-distribution' => sub {
        my $index = OrePAN2::Index->new;
        $index->add_index( 'Foo::Bar', '0.01', 'D/DU/DUMMY/Foo-Bar-0.01.tar.gz' );

        my $other = OrePAN2::Index->new;
        $other->add_index( 'Foo::Bar', '2.00', 'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz' );
        $other->add_index( 'Foo::Baz', '1.00', 'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz' );

        $index->merge( $other, protect_author => ['DUMMY'] );
        is [ $index->lookup('Foo::Bar') ]->[1],
            'D/DU/DUMMY/Foo-Bar-0.01.tar.gz';
        is [ $index->lookup('Foo::Baz') ]->[1],
            'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz';
    };

    subtest 'unmatched protect_author warns, does not die' => sub {
        my $index = OrePAN2::Index->new;
        $index->add_index( 'Foo::Bar', '2.00', 'C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz' );

        my $stderr = do {
            open my $fh, '>', \my $captured or die $!;
            local *STDERR = $fh;
            eval { $index->merge( OrePAN2::Index->new, protect_author => ['NOBODY'] ) };
            $captured;
        };
        is $@, '', 'does not die';
        like $stderr, qr/NOBODY/, 'warns about the unmatched author';
    };
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

subtest 'write_gzip' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $gzip = Path::Tiny->tempfile( SUFFIX => '.gz' );

    $index->write_gzip("$gzip");

    my $copy = OrePAN2::Index->new;
    $copy->load("$gzip");
    is(
        $copy->as_string( { simple => 1 } ),
        $index->as_string( { simple => 1 } ),
        'Got the same contents'
    );
};

subtest 'write_gzip forwards options to as_string' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $gzip = Path::Tiny->tempfile( SUFFIX => '.gz' );
    $index->write_gzip( "$gzip", { simple => 1 } );

    my $decompressed;
    IO::Uncompress::Gunzip::gunzip( "$gzip" => \$decompressed )
        or die
        "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
    is $decompressed, $index->as_string( { simple => 1 } ),
        '{ simple => 1 } was forwarded to as_string';
};

subtest 'write_gzip dies when destination directory is missing' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');

    my $tempdir  = Path::Tiny->tempdir;
    my $bad_path = $tempdir->child( 'does-not-exist', 'foo.gz' );
    eval { $index->write_gzip("$bad_path") };
    like $@, qr/does-not-exist/i,
        'error message references the missing directory';
    ok !-e "$bad_path", 'no partial file was written';
};

done_testing;

