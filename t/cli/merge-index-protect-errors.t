use strict;
use warnings;
use utf8;

use Capture::Tiny qw( capture );
use File::Temp qw( SEEK_SET );
use Test::More;

my $SCRIPT = 'script/orepan2-merge-index';

sub write_index {
    my (@lines) = @_;
    my $fh = File::Temp->new;
    print {$fh} <<'...';
File:         02packages.details.txt
Columns:      package name, version, path

...
    print {$fh} "$_\n" for @lines;
    $fh->close;
    return $fh;
}

# Every failure path under test writes a diagnostic to STDERR. That output is
# the expected behaviour, not test noise, so capture it and hand it to note()
# instead of letting it interleave with the TAP stream.
sub run_merge {
    my (@args) = @_;

    my ( $out, $err, $status )
        = capture { system $^X, '-Ilib', $SCRIPT, @args };

    note "STDOUT: $out" if length $out;
    note "STDERR: $err" if length $err;

    return $status >> 8;
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot read $file: $!";
    return do { local $/; <$fh> };
}

my @OREPAN = (
    'Foo::Bar               0.01                   D/DU/DUMMY/Foo-Bar-0.01.tar.gz',
);
my @CPAN = (
    'Foo::Bar               2.00                   C/CP/CPANAUTH/Foo-Bar-2.00.tar.gz',
);

subtest '-o file is not clobbered when --orepan/--cpan pairing check fails' => sub {
    my $orepan = write_index(@OREPAN);

    my $out = File::Temp->new;
    print {$out} "PRECIOUS EXISTING INDEX\n";
    $out->close;

    isnt run_merge( '-o', $out->filename, '--orepan', $orepan->filename ), 0,
        'exits non-zero on --orepan without --cpan';

    is slurp( $out->filename ), "PRECIOUS EXISTING INDEX\n",
        'the pre-existing output file is left untouched';
};

subtest '--protect-orepan-author in positional mode is a usage error' => sub {
    my $orepan = write_index(@OREPAN);
    my $cpan   = write_index(@CPAN);
    my $out    = File::Temp->new;

    isnt run_merge(
        '-o', $out->filename,
        '--protect-orepan-author', 'DUMMY',
        $orepan->filename, $cpan->filename,
        ),
        0,
        'refuses to silently ignore the flag in positional mode';
};

subtest 'author ids are matched case-insensitively' => sub {
    my $orepan = write_index(@OREPAN);
    my $cpan   = write_index(@CPAN);
    my $out    = File::Temp->new;

    is run_merge(
        '-o', $out->filename,
        '--orepan', $orepan->filename,
        '--cpan',   $cpan->filename,
        '--protect-orepan-author', 'dummy',
        ),
        0,
        'runs successfully';

    my $result = slurp( $out->filename );
    note $result;

    like $result, qr{Foo::Bar\s+0\.01\s+D/DU/DUMMY},
        'lower-case author id still protects the package';
};

subtest 'stray positional arguments are rejected' => sub {
    my $orepan = write_index(@OREPAN);
    my $cpan   = write_index(@CPAN);
    my $extra  = write_index(
        'Extra::Package         1.00                   E/EX/EXTRA/Extra-Package-1.00.tar.gz'
    );
    my $out = File::Temp->new;

    isnt run_merge(
        '-o', $out->filename,
        '--orepan', $orepan->filename,
        '--cpan',   $cpan->filename,
        $extra->filename,
        ),
        0,
        'refuses to silently drop the leftover positional argument';
};

subtest '-o file is not clobbered when an input file cannot be read' => sub {
    my $orepan = write_index(@OREPAN);

    my $out = File::Temp->new;
    print {$out} "PRECIOUS EXISTING INDEX\n";
    $out->close;

    isnt run_merge(
        '-o', $out->filename,
        '--orepan', $orepan->filename,
        '--cpan',   '/nonexistent/path/to/02packages.details.txt.gz',
        ),
        0,
        'exits non-zero when an input index cannot be read';

    is slurp( $out->filename ), "PRECIOUS EXISTING INDEX\n",
        'the pre-existing output file is left untouched';
};

subtest 'an unrecognised option is a usage error' => sub {
    my $orepan = write_index(@OREPAN);
    my $cpan   = write_index(@CPAN);

    my $out = File::Temp->new;
    print {$out} "PRECIOUS EXISTING INDEX\n";
    $out->close;

    isnt run_merge(
        '-o', $out->filename,
        '--bogus-option',
        '--orepan', $orepan->filename,
        '--cpan',   $cpan->filename,
        ),
        0,
        'exits non-zero on an unrecognised option';

    is slurp( $out->filename ), "PRECIOUS EXISTING INDEX\n",
        'the pre-existing output file is left untouched';
};

subtest 'write failures on the output file are fatal' => sub {
    plan skip_all => '/dev/full not available'
        unless -w '/dev/full';

    my $orepan = write_index(@OREPAN);
    my $cpan   = write_index(@CPAN);

    # open() succeeds and the print fails, so the failure is only visible if
    # both the print and the close are checked. script/orepan2-merge-index
    # checks both, as Indexer::write_index does; this test is what keeps them
    # checked.
    isnt run_merge(
        '-o', '/dev/full',
        '--orepan', $orepan->filename,
        '--cpan',   $cpan->filename,
        ),
        0,
        'exits non-zero when the index cannot be written';
};

done_testing;
