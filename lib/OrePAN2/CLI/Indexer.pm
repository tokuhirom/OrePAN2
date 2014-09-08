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
    my $text;
    my $metacpan;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptionsfromarray(
        \@args => (
            'metacpan!'      => \$metacpan,
            'version!'       => \$version,
            'text!'          => \$text,
        )
    );
    if ($version) {
        print "orepan2: $OrePAN2::VERSION\n";
    }
    my $directory = shift @args or pod2usage(
        -input => $0,
    );

    my $orepan = OrePAN2::Indexer->new(
        directory => $directory,
        metacpan  => $metacpan,
    );
    $orepan->make_index(
        no_compress => $text,
    );
}

1;
