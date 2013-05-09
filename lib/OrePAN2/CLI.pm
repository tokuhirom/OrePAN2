package OrePAN2::CLI;
use strict;
use warnings;
use utf8;
use Getopt::Long ();

sub new {
    my $class = shift;
    bless {}, $class;
}

sub run {
    my ($self, @args) = @_;

    my $version;
    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'version!'       => \$version,
    );
    if ($version) {
        print "orepan2: $OrePAN2::VERSION\n";
    }
    my $directory = shift @ARGV or pod2usage(1);

    my $orepan = OrePAN2->new(
        directory => $directory,
    );
    $orepan->make_index();
}

1;
