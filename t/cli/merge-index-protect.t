use strict;
use warnings;
use utf8;

use File::Temp qw( SEEK_SET );
use Test::More;

my $orepan = File::Temp->new();
print {$orepan} <<'...';
File:         02packages.details.txt
Columns:      package name, version, path

Foo::Bar               0.01                   D/DU/DUMMY/Foo-Bar-0.01.tar.gz
Baz::Qux               0.05                   W/WA/WATERKIP/Baz-Qux-0.05.tar.gz
Unowned::Thing         0.02                   Z/ZZ/OTHER/Unowned-Thing-0.02.tar.gz
...
$orepan->close;

my $cpan = File::Temp->new();
print {$cpan} <<'...';
File:         02packages.details.txt
Columns:      package name, version, path

Foo::Bar               2.00                   C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz
Baz::Qux               9.00                   C/CP/CPANAUTH/Baz-Qux-9.00.tar.gz
Unowned::Thing         0.03                   C/CP/CPANAUTH/Unowned-Thing-0.03.tar.gz
New::Package           1.00                   C/CP/CPANAUTH/New-Package-1.00.tar.gz
...
$cpan->close;

my $out = File::Temp->new();
is system(
    $^X, '-Ilib', 'script/orepan2-merge-index',
    '-o', $out->filename,
    '--orepan', $orepan->filename,
    '--cpan',   $cpan->filename,
    '--protect-orepan-author', 'DUMMY',
    '--protect-orepan-author', 'WATERKIP',
    ),
    0;
$out->seek( 0, SEEK_SET );
my $result = do { local $/; <$out> };
note $result;

like $result, qr/Foo::Bar\s+0\.01\s+D\/DU\/DUMMY/,
    'protected DUMMY package keeps its orepan version';
like $result, qr/Baz::Qux\s+0\.05\s+W\/WA\/WATERKIP/,
    'protected WATERKIP package keeps its orepan version';
like $result, qr/Unowned::Thing\s+0\.03\s+C\/CP\/CPANAUTH/,
    'unprotected package still takes the higher CPAN version';
like $result, qr/New::Package\s+1\.00\s+C\/CP\/CPANAUTH/,
    'CPAN-only package is added';

done_testing;
