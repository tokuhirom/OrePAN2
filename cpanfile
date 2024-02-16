use strict;
use warnings;

on 'runtime' => sub {
    requires 'perl'    => '5.012000';
    requires 'autodie' => '0';

    requires 'Archive::Extract'            => '0.72';
    requires 'Archive::Tar'                => '1.46';
    requires 'CPAN::Meta'                  => '2.131560';
    requires 'Digest::MD5'                 => '0';
    requires 'ExtUtils::MakeMaker'         => '7.06';
    requires 'File::Path'                  => '0';
    requires 'File::Spec'                  => '0';
    requires 'File::Temp'                  => '0';
    requires 'File::pushd'                 => '0';
    requires 'File::stat'                  => '0';
    requires 'Getopt::Long'                => '2.39';
    requires 'HTTP::Tiny'                  => '0';
    requires 'IO::File::AtomicChange'      => '0';
    requires 'IO::Socket::SSL'             => '1.42';
    requires 'IO::Uncompress::Gunzip'      => '0';
    requires 'IO::Zlib'                    => '0';
    requires 'JSON::PP'                    => '0';
    requires 'LWP::UserAgent'              => '0';
    requires 'List::Compare'               => '0';
    requires 'MetaCPAN::Client'            => '2.000000';
    requires 'Moo'                         => '1.007000';
    requires 'MooX::Options'               => '0';
    requires 'MooX::StrictConstructor'     => '0';
    requires 'Parse::CPAN::Meta'           => '1.4414';
    requires 'Parse::CPAN::Packages::Fast' => '0.09';
    requires 'Parse::LocalDistribution'    => '0.14';
    requires 'Path::Tiny'                  => '0';
    requires 'Pod::Usage'                  => '0';
    requires 'Try::Tiny'                   => '0';
    requires 'Type::Tiny'                  => '2.000000';
    requires 'Types::Path::Tiny'           => '0';
    requires 'Types::Self'                 => '0';
    requires 'Types::URI'                  => '0';
    requires 'feature'                     => '0';
    requires 'namespace::clean'            => '0';
    requires 'parent'                      => '0';
    requires 'version'                     => '0.9912';
};

on 'test' => sub {
    requires 'File::Touch'            => '0';
    requires 'File::Which'            => '0';
    requires 'Path::Tiny'             => '0.119';
    requires 'Test::More'             => '0.98';
    requires 'Test::RequiresInternet' => '0.02';
};

on 'develop' => sub {
    requires 'Test::MinimumVersion::Fast' => '0';
    requires 'Test::PAUSE::Permissions'   => '0';
    requires 'Test::Spellunker'           => '0';
};
