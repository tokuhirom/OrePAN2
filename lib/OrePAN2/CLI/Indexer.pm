package OrePAN2::CLI::Indexer;
use strict;
use warnings;
use utf8;

use Getopt::Long ();
use Pod::Usage;
use OrePAN2;
use OrePAN2::Indexer;

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
    my $directory = shift @ARGV or pod2usage(
        -input => $0,
    );

    my $orepan = OrePAN2::Indexer->new(
        directory => $directory,
    );
    $orepan->make_index();
}

1;
