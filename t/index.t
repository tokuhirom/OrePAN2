use strict;
use warnings;
use utf8;
use Test::More;
use OrePAN2::Index;

for my $file ('t/dat/02.packages.details.txt', 't/dat/02.packages.details.txt.gz') {
    subtest $file => sub {
        my $index = OrePAN2::Index->load('t/dat/02.packages.details.txt');
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

done_testing;

