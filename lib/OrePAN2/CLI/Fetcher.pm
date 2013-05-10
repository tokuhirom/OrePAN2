package OrePAN2::CLI::Fetcher;
use strict;
use warnings;
use utf8;

use Getopt::Long ();
use Pod::Usage;
use OrePAN2;
use OrePAN2::Fetcher;

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
    my $directory = pop @ARGV or pod2usage(
        -input => $0,
    );

    my $fetcher = OrePAN2::Fetcher->new(
        directory => $directory,
    );
    if (@ARGV) {
        for (@ARGV) {
            next unless /\S/;
            $fetcher->fetch($_);
        }
    } else {
        while (<>) {
            chomp;
            next unless /\S/;
            $fetcher->fetch($_);
        }
    }
}

1;

