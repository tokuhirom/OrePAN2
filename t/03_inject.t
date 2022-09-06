use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More;
use Test::More;
use Local::Util;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Copy qw(copy);

use OrePAN2::Injector;

subtest 'gz' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
    );
    $injector->inject(
        't/dat/Acme-YakiniQ-0.01.tar.gz',
        { author => 'MIYAGAWA' }
    );
    ok -f "$tmpdir/authors/id/M/MI/MIYAGAWA/Acme-YakiniQ-0.01.tar.gz";
};

subtest 'author name must be upper case' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
    );
    $injector->inject( 't/dat/Acme-Foo-0.01.tar.gz', { author => 'upper' } );
    ok -f "$tmpdir/authors/id/U/UP/UPPER/Acme-Foo-0.01.tar.gz";
};

subtest 'extra path after author name' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
    );
    $injector->inject(
        't/dat/Acme-Foo-0.01.tar.gz',
        { author => 'upper', author_subdir => 'abcd' }
    );
    ok -f "$tmpdir/authors/id/U/UP/UPPER/abcd/Acme-Foo-0.01.tar.gz";
};

subtest 'check that $self->{author} is used' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author    => 'MIYAGAWA',
    );
    $injector->inject('t/dat/Acme-Foo-0.01.tar.gz');
    ok -f "$tmpdir/authors/id/M/MI/MIYAGAWA/Acme-Foo-0.01.tar.gz";
};

subtest 'check that code reference $self->{author} works' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $injector = OrePAN2::Injector->new(
        directory => $tmpdir,
        author    => sub {
            my $file = shift;
            require CPAN::Meta;
            my $meta   = CPAN::Meta->load_file("META.json");
            my $author = $meta->{author}[0]; # tokuhirom <tokuhirom@gmail.com>
            $author =~ s/\s.*//;
            uc $author;
        },
    );
    $injector->inject('t/dat/Acme-Foo-0.01.tar.gz');
    ok -f "$tmpdir/authors/id/T/TO/TOKUHIROM/Acme-Foo-0.01.tar.gz";
};

done_testing;
