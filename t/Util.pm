package t::Util;
use strict;
use warnings;
use utf8;

use parent qw(Exporter);

our @EXPORT = qw(slurp);

sub slurp {
    my $name = shift;
    open my $fh, '<', $name
        or die "Cannot open '$name' for reading: $!";
    do { local $/; <$fh> };
}

1;

