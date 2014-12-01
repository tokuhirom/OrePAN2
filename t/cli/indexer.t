use strict;
use warnings;
use utf8;
use Test::More;

use OrePAN2::CLI::Indexer;
use File::pushd;
use File::Temp qw(tempdir);
use Pod::Usage;
use t::Util;

{
    no warnings 'redefine';
    *OrePAN2::CLI::Indexer::pod2usage = sub {
        die "SHOULD NOT REACH HERE: pod2usage";
    };
}

subtest 'gz index' => sub {
    my $tmp = pushd( tempdir() );
    OrePAN2::CLI::Indexer->new()->run($tmp);
    ok -f 'modules/02packages.details.txt.gz';
};

subtest 'txt index' => sub {
    my $tmp = pushd( tempdir() );
    OrePAN2::CLI::Indexer->new()->run( '--text', $tmp );
    ok -f 'modules/02packages.details.txt';
    my $txt = slurp 'modules/02packages.details.txt';
    note $txt;
    like $txt, qr/Description:\s+DarkPAN/;
};

done_testing;

__END__

=head1 SYNOPSIS

    DO NOT DISPLAY THIS FILE.

