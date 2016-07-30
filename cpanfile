requires 'perl', '5.008001';
requires 'autodie';

requires 'Archive::Extract', 0.72;
requires 'Archive::Tar';
requires 'CPAN::Meta', 2.131560;
requires 'Class::Accessor::Lite', '0.05';
requires 'Digest::MD5';
requires 'File::Path';
requires 'File::Temp';
requires 'File::pushd';
requires 'Getopt::Long', 2.39;
requires 'HTTP::Tiny';
requires 'IO::File::AtomicChange';
requires 'IO::Socket::SSL', 1.42;
requires 'IO::Uncompress::Gunzip';
requires 'IO::Zlib';
requires 'JSON::PP';
requires 'LWP::UserAgent';
requires 'List::Compare';
requires 'MetaCPAN::Client', '1.021000';
requires 'Moo', '1.007000';
requires 'MooX::Options';
requires 'Parse::CPAN::Meta', '1.4414';
requires 'Parse::CPAN::Packages', '2.39';
requires 'Parse::LocalDistribution', '0.14';
requires 'Parse::PMFile', '0.29';
requires 'Path::Tiny';
requires 'Pod::Usage';
requires 'Ref::Util';
requires 'Try::Tiny';
requires 'Type::Params';
requires 'Types::URI';
requires 'parent';
requires 'version', '0.9912';

on 'test' => sub {
    requires 'File::Which';
    requires 'PAUSE::Packages';
    requires 'Test::More', '0.98';
    requires 'Test::RequiresInternet', '0.02';
};

