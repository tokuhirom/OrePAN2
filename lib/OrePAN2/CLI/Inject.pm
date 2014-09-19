package OrePAN2::CLI::Inject;

use strict;
use warnings;
use utf8;

use Getopt::Long ();
use OrePAN2;
use OrePAN2::Indexer;
use OrePAN2::Injector;
use OrePAN2::Repository;
use Pod::Usage;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub run {
    my ($self, @args) = @_;

    my $version;
    my $generate_index = 1;
    my $author = 'DUMMY';
    my $simple;
    my $text;
    my $enable_cache = 0;
    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'version!'       => \$version,
        'generate-index!' => \$generate_index,
        'author=s'        => \$author,
        'simple!'         => \$simple,
        'text!'           => \$text,
        'cache!'          => \$enable_cache,
    );
    if ($version) {
        print "orepan2: $OrePAN2::VERSION\n";
    }
    my $directory = pop @ARGV or pod2usage(
        -input => $0,
    );

    my $repository = OrePAN2::Repository->new(
        directory      => $directory,
        compress_index => !$text,
        simple         => $simple,
    );
    if (@ARGV) {
        for (@ARGV) {
            next unless /\S/;
            next if $enable_cache && $repository->has_cache($_);

            my $tarpath = $repository->inject($_, {author => $author});
            print "Wrote $tarpath from $_\n";
        }
    } else {
        while (<>) {
            chomp;
            next unless /\S/;
            next if $enable_cache && $repository->has_cache($_);

            my $tarpath = $repository->inject($_, {author => $author});
            print "Wrote $tarpath from $_\n";
        }
    }

    return unless $repository->cache->is_dirty;

    $repository->save_cache;

    if ($generate_index) {
        $repository->make_index();
    }
}

1;

