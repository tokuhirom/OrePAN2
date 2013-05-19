package t::Util;
use strict;
use warnings;
use utf8;
use Carp ();

use parent qw(Exporter);

our @EXPORT = qw(slurp slurp_gz);

sub slurp {
    my $name = shift;
    open my $fh, '<', $name
        or die "Cannot open '$name' for reading: $!";
    do { local $/; <$fh> };
}

sub slurp_gz {
    my $name = shift;
    open my $fh, '<:gzip', $name
        or Carp::croak "Cannot open '$name' for reading: $!";
    do { local $/; <$fh> };
}

1;

