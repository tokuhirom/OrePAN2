package OrePAN2::Role::HasLogger;
use OrePAN2::Logger;

use Moo::Role;

has log => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_log',
);

sub _build_log {
    OrePAN2::Logger->new->get_logger;
}

1;
