package OrePAN2;
use 5.008005;
use strict;
use warnings;
use File::Find qw(find);
use Module::Metadata ();
use File::Spec ();
use File::Basename ();
use Archive::Extract ();
use OrePAN2::Index;
use File::Temp qw(tempdir);

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    unless (defined $args{directory}) {
        Carp::croak("Missing mandatory parameter: directory");
    }
    bless {
        %args,
    }, $class;
}

sub directory { shift->{directory} }

sub make_index {
    my $self = shift;

    my @files = $self->list_tar_files();
    my $index = OrePAN2::Index->new();
    for my $archive_file (@files) {
        $self->add_index($index, $archive_file);
    }
    $self->write_index($index);
}

sub add_index {
    my ($self, $index, $archive_file) = @_;

    my $archive = Archive::Extract->new(
        archive => $archive_file
    );
    my $tmpdir = tempdir( CLEANUP => 1 );
    $archive->extract( to => $tmpdir);

    my $provides = Module::Metadata->provides(
        dir => $tmpdir,
        version => 2,
    );
    while (my ($package, $data) = each %$provides) {
        my $version = $provides->{$package}->{version};
        $index->add_index(
            $package,
            $version,
            File::Spec->abs2rel($archive_file, File::Spec->catfile($self->directory, 'authors', 'id')),
        );
    }
}

sub write_index {
    my ($self, $index) = @_;

    my $pkgfname = File::Spec->catfile($self->directory, 'modules', '02packages.details.txt');
    mkdir(File::Basename::dirname($pkgfname));
    open my $fh, '>', $pkgfname,
        or die "Cannot open $pkgfname for writing: $!\n";
    print $fh $index->as_string();
    close $fh;
}

sub list_tar_files {
    my $self = shift;

    my @files;
    find(
        {
            wanted => sub {
                return unless /
                    (?:
                          \.tar\.gz
                        | \.zip
                    )
                \z/x;
                push @files, $_;
            },
            no_chdir => 1,
        }, File::Spec->catfile($self->{directory}, 'authors')
    );
    return @files;
}

1;
__END__

=encoding utf-8

=head1 NAME

OrePAN2 - It's new $module

=head1 SYNOPSIS

    use OrePAN2;

=head1 DESCRIPTION

OrePAN2 is ...

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

