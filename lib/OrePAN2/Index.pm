package OrePAN2::Index;
use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
    }, $class;
}

sub as_string {
    '';
}

1;

