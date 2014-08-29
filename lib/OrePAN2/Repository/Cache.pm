package OrePAN2::Repository::Cache;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Carp;
use File::Spec;
use JSON::PP;
use Digest::MD5;
use IO::File::AtomicChange;
use File::Path;
use File::stat;

use Class::Accessor::Lite 0.05 (
    rw => [qw(is_dirty directory)],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    for my $key (qw(directory)) {
        unless (exists $args{$key}) {
            Carp::croak("Missing mandatory parameter: $key");
        }
    }
    my $self = bless {
        %args,
    }, $class;
    $self->{filename} = File::Spec->catfile($self->{directory}, 'orepan2-cache.json');
    return $self;
}

sub data {
    my $self = shift;
    $self->{data} ||= do {
        if (open my $fh, '<', $self->{filename}) {
            JSON::PP::decode_json(do { local $/; <$fh> });
        } else {
            +{};
        }
    };
}

sub is_hit {
    my ($self, $stuff) = @_;

    my $entry = $self->data->{$stuff};

    return 0 unless $entry && $entry->{filename} && $entry->{md5};

    my $fullpath = File::Spec->catfile($self->directory, $entry->{filename});
    return 0 unless -f $fullpath;

    if (my $stat = stat($stuff) && defined($entry->{mtime})) {
        return 0 if $stat->mtime ne $entry->{mtime}
    }

    my $md5 = $self->calc_md5($fullpath);
    return 0 unless $md5;
    return 0 if $md5 ne $entry->{md5};
    return 1;
}

sub calc_md5 {
    my ($self, $filename) = @_;

    open my $fh, '<', $filename
        or do {
        return;
    };

    my $md5 = Digest::MD5->new();
    $md5->addfile($fh);
    return $md5->hexdigest;
}

sub set {
    my ($self, $stuff, $filename) = @_;

    my $md5 = $self->calc_md5(File::Spec->catfile($self->directory, $filename))
        or Carp::croak("Cannot calcurate MD5 for '$filename'");
    $self->{data}->{$stuff} = +{
        filename => $filename,
        md5      => $md5,
        (-f $filename ? (mtime => stat($filename)->mtime) : ()),
    };
    $self->is_dirty(1);
}

sub save {
    my ($self) = @_;

    my $filename = $self->{filename};
    my $json = JSON::PP->new->pretty(1)->canonical(1)->encode($self->{data});

    File::Path::mkpath(File::Basename::dirname($filename));

    my $fh = IO::File::AtomicChange->new($filename, 'w');
    $fh->print($json);
    $fh->close(); # MUST CALL close EXPLICITLY
}

1;

