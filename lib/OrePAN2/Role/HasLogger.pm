package OrePAN2::Role::HasLogger;

use Moo::Role;

has log => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_log',
);

sub _build_log {
    require OrePAN2::Logger;
    OrePAN2::Logger->new->get_logger;
}

1;
