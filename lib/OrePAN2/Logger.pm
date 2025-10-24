package OrePAN2::Logger;

use Moo;

# trace
# debug
# info (inform)
sub info { print STDERR "[INFO] $_[1]\n" }

# notice
# warning (warn)
sub warn { print STDERR "[WARN] $_[1]\n" }

# error (err)
# critical (crit, fatal)
# alert
# emergency

1;
