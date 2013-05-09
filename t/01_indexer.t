use strict;
use warnings;
use utf8;
use Test::More;

use OrePAN2;

my $orepan = OrePAN2->new(
    directory => 't/dat',
);
$orepan->make_index();

done_testing;

