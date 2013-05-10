package OrePAN2::Index;
use strict;
use warnings;
use utf8;
use OrePAN2;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
    }, $class;
}

sub add_index {
    my ($self, $package, $version, $archive_file) = @_;

    push @{$self->{index}}, [$package, $version, $archive_file];
}

sub as_string {
    my $self = shift;

    my @buf;

    push @buf, (
        'File:         02packages.details.txt',
        'URL:          http://www.perl.com/CPAN/modules/02packages.details.txt',
        'Description:  DarkPAN',
        'Columns:      package name, version, path',
        'Intended-For: Automated fetch routines, namespace documentation.',
        "Written-By:   OrePAN2 $OrePAN2::VERSION",
        "Line-Count:   @{[ scalar(@{$self->{index}}) ]}",
        "Last-Updated: @{[ scalar localtime ]}",
        '',
    );

    for my $row (sort { $a->[0] cmp $b->[0] } @{$self->{index}}) {
        # package name, version, path
        push @buf, sprintf "%-22s %-22s %s", $row->[0], $row->[1] || 'undef', $row->[2];
    }
    return join("\n", @buf) . "\n";
}

1;

