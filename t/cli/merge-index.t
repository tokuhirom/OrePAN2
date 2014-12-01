use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use File::Temp;

my $f1 = File::Temp->new();
print {$f1} <<'...';
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  DarkPAN
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.

AAA::Demo              undef                  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
...
$f1->close;

my $f2 = File::Temp->new();
print {$f2} <<'...';
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  DarkPAN
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.

AAA::eBay              undef                  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
...
$f2->close;

my $out = File::Temp->new();
is system( $^X, '-Ilib', 'script/orepan2-merge-index', '-o', $out->filename,
    $f1->filename, $f2->filename
    ),
    0;
$out->seek( 0, SEEK_SET );
my $result = do { local $/; <$out> };
note $result;

like $result, qr/AAA::eBay/, 'AAA::eBay is indexed';
like $result, qr/AAA::Demo/, 'AAA::Demo is also indexed';

done_testing;

