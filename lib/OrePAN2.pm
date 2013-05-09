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
    extract($archive_file);
    my @pm_files = $self->list_pm_files();
    for my $pm_file (@pm_files) {
        my $meta = Module::Metadata->new($pm_file);
        for my $pkg ($meta->provides()) {
            $index->add($pkg, $archive_file);
        }
    }
}

sub write_index {
    my ($self, $index) = @_;

    my $pkgfname = File::Spec->catfile($self->directory, 'modules', '02.packages.txt');
    mkdir(File::Basename::dirname($pkgfname));
    open my $fh, '>', $pkgfname,
        or die "Cannot open $pkgfname for writing: $!\n";
    print $fh $index->as_string();
    close $fh;
}

sub list_pm_files {
    my $self = shift;
    my @files;
    find(
        {
            wanted => sub {
                return unless /
                    (?:
                          \.pm
                    )
                \z/x;
                push @files, $_;
            },
            no_chdir => 1,
        }, $self->{directory}
    );
    return @files;
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
        }, $self->{directory}
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

