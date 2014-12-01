use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);

use OrePAN2::CLI::Inject;

no warnings 'redefine';
*OrePAN2::CLI::Inject::pod2usage = sub { die };

# test case for https://github.com/tokuhirom/OrePAN2/issues/6#issuecomment-21912528
{
    my $url
        = 'http://search.cpan.org/CPAN/authors/id/M/MI/MIYAGAWA/Devel-StackTrace-AsHTML-0.14.tar.gz';
    my $tmpdir = tempdir( CLEANUP => 1 );
    local @ARGV = ( '--text', $url, $tmpdir );
    OrePAN2::CLI::Inject->new->run();
    ok( -f "$tmpdir/authors/id/D/DU/DUMMY/Devel-StackTrace-AsHTML-0.14.tar.gz"
    );
    ok( -f "$tmpdir/modules/02packages.details.txt" );
    my $details = slurp("$tmpdir/modules/02packages.details.txt");
    note $details;
    like $details,
        qr(Devel::StackTrace::AsHTML 0.14                   D/DU/DUMMY/Devel-StackTrace-AsHTML-0.14.tar.gz);
    unlike $details, qr(Module::Install);
}

done_testing;

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(
        do { local $/; <$fh> }
    );
}
