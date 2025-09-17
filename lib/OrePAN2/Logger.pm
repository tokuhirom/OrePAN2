package OrePAN2::Logger;
use strict;
use warnings;

use Moo;
use namespace::clean;

# Default logger implementation that prints to STDERR
# Can be replaced with any object that has info() and warn() methods

sub info {
    my ($self, $message) = @_;
    print STDERR "[INFO] $message\n";
}

sub warn {
    my ($self, $message) = @_;
    print STDERR "[WARN] $message\n";
}

1;

__END__

=head1 NAME

OrePAN2::Logger - Default logger for OrePAN2

=head1 DESCRIPTION

This is the default logger implementation for OrePAN2. It simply prints
log messages to STDERR with appropriate prefixes.

This can be replaced with any logger object that implements the C<info()>
and C<warn()> methods, such as Log::Any loggers or Mojo::Log.

=head1 METHODS

=head2 info($message)

Log an informational message.

=head2 warn($message)

Log a warning message.

=cut