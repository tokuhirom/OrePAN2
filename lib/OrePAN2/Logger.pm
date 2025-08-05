package OrePAN2::Logger;
use strict;
use warnings;

use Moo;
use namespace::clean;

has log => ( is => 'ro', writer => '_set_log' );

sub get_logger {
    my ($self) = @_;
    $self->_set_log( bless {}, 'OrePAN2::Logger' );
    return ( $self->log );
}

# trace
# debug
# info (inform)
sub info { shift; print STDERR "[INFO] $_[0]\n" }

# notice
# warning (warn)
sub warn { shift; print STDERR "[WARN] $_[0]\n" }

# error (err)
# critical (crit, fatal)
# alert
# emergency

1;
