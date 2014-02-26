use strict;
use warnings;
use utf8;
use Test::More;
use OrePAN2::Index;

subtest 'load, lookup' => sub {
    for my $file ('t/dat/02.packages.details.txt', 't/dat/02.packages.details.txt.gz') {
        subtest $file => sub {
            my $index = OrePAN2::Index->new();
            $index->load($file);
            subtest 'The package has undef version', sub {
                my ($ver, $path) = $index->lookup('A_Third_Package');
                is $ver, undef;
                is $path, 'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz';
            };
            subtest 'has a version', sub {
                my ($ver, $path) = $index->lookup('AAAA::Crypt::DH');
                is $ver, '0.04';
                is $path, 'B/BI/BINGOS/AAAA-Crypt-DH-0.04.tar.gz';
            };
        };
    }
};

subtest 'delete' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');
    ok [$index->lookup('A_Third_Package')]->[1], 'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz';
    $index->delete_index('A_Third_Package');
    is [$index->lookup('A_Third_Package')]->[1], undef;
};

subtest 'as_string' => sub {
    my $index = OrePAN2::Index->new;
    $index->load('t/dat/02.packages.details.txt');
    like $index->as_string, qr{A_Third_Package};
};

done_testing;

