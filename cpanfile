requires 'perl', '5.008001';

requires 'Archive::Extract', 0.68;
requires 'Archive::Tar';
requires 'CPAN::Meta';
requires 'File::Temp';
requires 'File::pushd';
requires 'Getopt::Long', 2.39;
requires 'HTTP::Tiny';
requires 'Module::Metadata';
requires 'PerlIO::gzip';
requires 'Pod::Usage';
requires 'parent';
requires 'Parse::PMFile';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

