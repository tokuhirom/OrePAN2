requires 'perl', '5.008001';

requires 'Archive::Extract', 0.72;
requires 'Archive::Tar';
requires 'CPAN::Meta', 2.131560;
requires 'File::Temp';
requires 'File::pushd';
requires 'Getopt::Long', 2.39;
requires 'HTTP::Tiny';
requires 'IO::Socket::SSL', 1.42;
requires 'Parse::LocalDistribution', '0.14';
requires 'Parse::CPAN::Meta', '1.4414';
requires 'Parse::PMFile', '0.29';
requires 'IO::Zlib';
requires 'Pod::Usage';
requires 'MetaCPAN::Client', 1.006000;
requires 'IO::Uncompress::Gunzip';
requires 'parent';
requires 'Class::Accessor::Lite', '0.05';
requires 'Digest::MD5';
requires 'File::Path';
requires 'IO::File::AtomicChange';
requires 'JSON::PP';
requires 'Path::Tiny';
requires 'Try::Tiny';
requires 'version', '0.9909';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::RequiresInternet', '0.02';
    requires 'File::Which';
};

