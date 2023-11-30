use strict;
use warnings;

requires 'perl', '5.012000';
requires 'autodie';

requires 'Archive::Extract',      0.72;
requires 'Archive::Tar',          1.46;
requires 'CPAN::Meta',            2.131560;
requires 'Class::Accessor::Lite', '0.05';
requires 'Digest::MD5';
requires 'ExtUtils::MakeMaker', '7.06';
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
requires 'MetaCPAN::Client', '2.000000';
requires 'Moo',              '1.007000';
requires 'MooX::Options';
requires 'MooX::StrictConstructor';
requires 'Parse::CPAN::Meta',           '1.4414';
requires 'Parse::CPAN::Packages::Fast', '0.09';
requires 'Parse::LocalDistribution',    '0.14';
requires 'Parse::PMFile',               '0.29';
requires 'Path::Tiny';
requires 'Pod::Usage';
requires 'Try::Tiny';
requires 'Type::Tiny', '2.000000';
requires 'Types::Self';
requires 'Types::URI';
requires 'feature';
requires 'namespace::clean';
requires 'parent';
requires 'version', '0.9912';

on 'test' => sub {
    requires 'File::Touch';
    requires 'File::Which';
    requires 'PAUSE::Packages';
    requires 'Path::Class';
    requires 'Test::More',             '0.98';
    requires 'Test::RequiresInternet', '0.02';
};

on 'develop' => sub {
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Spellunker';
};
