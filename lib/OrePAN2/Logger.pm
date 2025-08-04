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

#sub warn { shift; print STDERR "[WARN] $_[0]\n" }
sub info { shift; print STDERR "[INFO] $_[0]\n" }

#sub debug { shift; print STDERR "[DEBUG] $_[0]\n" }
#sub error { shift; print STDERR "[ERROR] $_[0]\n" }

1;
