package OrePAN2::Repository;

use utf8;

use Moo;

use File::Find                 ();
use File::Spec                 ();
use File::pushd                ();
use OrePAN2::Indexer           ();
use OrePAN2::Injector          ();
use OrePAN2::Repository::Cache ();
use Types::Standard            qw( Bool InstanceOf Str );

use namespace::clean;

#<<<
has compress_index => ( is => 'ro',   isa => Bool, default => !!1 );
has cache          => ( is => 'lazy', isa => InstanceOf ['OrePAN2::Repository::Cache'], builder => 1, handles => { has_cache => 'is_hit', save_cache => 'save' } );
has directory      => ( is => 'ro',   isa => Str, required => 1 );
has indexer        => ( is => 'lazy', isa => InstanceOf ['OrePAN2::Indexer'],           builder => 1 );
has injector       => ( is => 'lazy', isa => InstanceOf ['OrePAN2::Injector'],          builder => 1 );
has simple         => ( is => 'ro',   isa => Bool, default => !!0 );
#>>>

sub _build_cache {
    my $self = shift;
    return OrePAN2::Repository::Cache->new( directory => $self->directory );
}

sub _build_indexer {
    my $self = shift;
    return OrePAN2::Indexer->new(
        directory => $self->directory,
        simple    => $self->simple
    );
}

sub _build_injector {
    my $self = shift;
    return OrePAN2::Injector->new( directory => $self->directory );
}

sub make_index {
    my $self = shift;
    $self->indexer->make_index( no_compress => !$self->compress_index );
}

sub inject {
    my ( $self, $stuff, $opts ) = @_;

    my $tarpath = $self->injector->inject( $stuff, $opts );
    $self->cache->set( $stuff, $tarpath );
}

sub index_file {
    my $self = shift;
    return File::Spec->catfile(
        $self->directory, 'modules',
        '02packages.details.txt' . ( $self->compress_index ? '.gz' : q{} )
    );
}

sub load_index {
    my $self = shift;

    my $index = OrePAN2::Index->new();
    $index->load( $self->index_file );
    $index;
}

# Remove files that are not referenced by the index file.
sub gc {
    my ( $self, $callback ) = @_;

    return unless -f $self->index_file;

    my $index = $self->load_index;
    my %registered;
    for my $package ( $index->packages ) {
        my ( $version, $path ) = $index->lookup($package);
        $registered{$path}++;
    }

    my $pushd = File::pushd::pushd(
        File::Spec->catdir( $self->directory, 'authors', 'id' ) );
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return unless -f $_;
                $_ = File::Spec->canonpath($_);
                unless ( $registered{$_} ) {
                    $callback ? $callback->($_) : unlink $_;
                }
                1;
            },
        },
        '.'
    );
}

1;

