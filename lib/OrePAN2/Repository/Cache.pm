package OrePAN2::Repository::Cache;

use utf8;

use Moo;

use Carp                   ();
use Digest::MD5            ();
use File::Path             ();
use File::Spec             ();
use File::stat             qw( stat );
use IO::File::AtomicChange ();
use JSON::PP               ();
use Types::Standard        qw( Bool HashRef Str );

use namespace::clean;

has directory => ( is => 'ro',   isa => Str,     required => 1 );
has data      => ( is => 'lazy', isa => HashRef, builder  => 1 );
has filename  => ( is => 'lazy', isa => Str,     builder  => 1 );
has is_dirty  => ( is => 'rw',   isa => Bool,    default  => !!0 );

sub _build_data {
    my $self = shift;
    return do {
        if ( open my $fh, '<', $self->filename ) {
            JSON::PP->new->utf8->decode(
                do { local $/; <$fh> }
            );
        }
        else {
            +{};
        }
    };
}

sub _build_filename {
    my $self = shift;
    return File::Spec->catfile( $self->directory, 'orepan2-cache.json' );
}

sub is_hit {
    my ( $self, $stuff ) = @_;

    my $entry = $self->data->{$stuff};

    return 0 unless $entry && $entry->{filename} && $entry->{md5};

    my $fullpath
        = File::Spec->catfile( $self->directory, $entry->{filename} );
    return 0 unless -f $fullpath;

    if ( my $stat = stat($stuff) && defined( $entry->{mtime} ) ) {
        return 0 if $stat->mtime ne $entry->{mtime};
    }

    my $md5 = $self->calc_md5($fullpath);
    return 0 unless $md5;
    return 0 if $md5 ne $entry->{md5};
    return 1;
}

sub calc_md5 {
    my ( $self, $filename ) = @_;

    open my $fh, '<', $filename
        or do {
        return;
        };

    my $md5 = Digest::MD5->new();
    $md5->addfile($fh);
    return $md5->hexdigest;
}

sub set {
    my ( $self, $stuff, $filename ) = @_;

    my $md5
        = $self->calc_md5(
        File::Spec->catfile( $self->directory, $filename ) )
        or Carp::croak("Cannot calculate MD5 for '$filename'");
    $self->data->{$stuff} = +{
        filename => $filename,
        md5      => $md5,
        ( -f $filename ? ( mtime => stat($filename)->mtime ) : () ),
    };
    $self->is_dirty(1);
}

sub save {
    my ($self) = @_;

    my $filename = $self->filename;
    my $json
        = JSON::PP->new->pretty(1)->canonical(1)->encode( $self->data );

    File::Path::mkpath( File::Basename::dirname($filename) );

    my $fh = IO::File::AtomicChange->new( $filename, 'w' );
    $fh->print($json);
    $fh->close();    # MUST CALL close EXPLICITLY
}

1;

