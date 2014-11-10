package OrePAN2::Repository;

use strict;
use warnings;
use utf8;
use 5.008_001;

use Carp;
use Class::Accessor::Lite 0.05 (
    rw => [qw(directory cache compress_index)],
);
use File::Find;
use File::Spec;
use File::pushd;
use OrePAN2::Indexer;
use OrePAN2::Injector;
use OrePAN2::Repository::Cache;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    for my $key (qw(directory)) {
        unless (exists $args{$key}) {
            Carp::croak("Missing mandatory parameter: $key");
        }
    }
    my $self = bless {
        compress_index => 1,
        %args,
    }, $class;
    $self->{cache} = OrePAN2::Repository::Cache->new(
        directory => $self->{directory}
    );

    return $self;
}

sub injector {
    my $self = shift;
    $self->{injector} ||= OrePAN2::Injector->new(
        directory => $self->directory,
    );
}

sub indexer {
    my $self = shift;
    $self->{indexer} ||= OrePAN2::Indexer->new(
        directory => $self->directory,
        simple    => $self->{simple},
    );
}

sub has_cache {
    my ($self, $stuff) = @_;
    $self->cache->is_hit($stuff);
}

sub make_index {
    my $self = shift;
    $self->indexer->make_index( no_compress => !$self->compress_index );
}

sub inject {
    my ($self, $stuff, $opts) = @_;

    my $tarpath = $self->injector->inject($stuff, $opts);
    $self->cache->set($stuff, $tarpath);
}

sub index_file {
    my $self = shift;
    return File::Spec->catfile($self->directory, 'modules', '02packages.details.txt' . ($self->compress_index ? '.gz' : ''));
}

sub save_cache {
    my $self = shift;
    $self->cache->save;
}

sub load_index {
    my $self = shift;

    my $index = OrePAN2::Index->new();
    $index->load($self->index_file);
    $index;
}

# Remove files that are not referenced by the index file.
sub gc {
    my ($self) = @_;

    return unless -f $self->index_file;

    my $index = $self->load_index;
    my %registered;
    for my $package ($index->packages) {
        my ($version, $path) = $index->lookup($package);
        $registered{$path}++;
    }

    my $pushd = File::pushd::pushd(File::Spec->catdir($self->directory, 'authors', 'id'));
    File::Find::find(
        {
            no_chdir => 1,
            wanted => sub {
                return unless -f $_;
                $_ = File::Spec->canonpath($_);
                unless ($registered{$_}) {
                    unlink $_;
                }
                1;
            },
        }, '.'
    );
}

1;

