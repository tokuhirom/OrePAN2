package OrePAN2::Role::HasLogger;

use OrePAN2::Logger;
use Moo::Role;

has log => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_log',
);

sub _build_log {
    return OrePAN2::Logger->new();
}

1;

__END__

=head1 NAME

OrePAN2::Role::HasLogger - Moo role for adding logging capability

=head1 DESCRIPTION

This role adds a C<log> attribute to any class that consumes it.
The logger defaults to L<OrePAN2::Logger> but can be overridden
by passing a different logger object to the constructor.

=head1 ATTRIBUTES

=head2 log

A logger object. Defaults to L<OrePAN2::Logger> but can be any object
that implements C<info()> and C<warn()> methods.

=head1 EXAMPLE

    package MyClass;
    use Moo;
    with 'OrePAN2::Role::HasLogger';
    
    sub do_something {
        my $self = shift;
        $self->log->info("Doing something");
    }
    
    # Use default logger
    my $obj = MyClass->new();
    
    # Use custom logger
    my $custom_logger = Log::Any->get_logger();
    my $obj2 = MyClass->new(log => $custom_logger);

=cut