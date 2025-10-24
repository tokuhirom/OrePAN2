package OrePAN2::Role::HasLogger;

use Moo::Role;

use OrePAN2::Logger ();

has log => (
    is      => 'ro',
    lazy    => 1,
    default => sub { OrePAN2::Logger->new },
);

1;
