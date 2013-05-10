package OrePAN2::CLI::Inject;
use strict;
use warnings;
use utf8;

use Getopt::Long ();
use Pod::Usage;
use OrePAN2;
use OrePAN2::Injector;

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

    my $injector = OrePAN2::Injector->new(
        directory => $directory,
    );
    if (@ARGV) {
        for (@ARGV) {
            next unless /\S/;
            $injector->inject($_);
        }
    } else {
        while (<>) {
            chomp;
            next unless /\S/;
            $injector->inject($_);
        }
    }
}

1;

