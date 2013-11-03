use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use File::Which ();
use OrePAN2::Injector;
use Test::More;

my $git = File::Which::which('git');
my $tar = File::Which::which('tar');
unless ($git and $tar) {
    plan skip_all => "This test depends on git and tar commands";
}

# Create dummy git repository
my $yakini_q = File::Spec->rel2abs('t/dat/Acme-YakiniQ-0.01.tar.gz');
my $gitrepo = tempdir CLEANUP => 1;
chdir $gitrepo;
system ($tar, 'zxvf', $yakini_q);
$gitrepo = File::Spec->catfile($gitrepo, (<*>)[0]);

chdir $gitrepo;
system ($git, 'init');
system ($git, 'config', 'user.email', 'hiratara@cpan.org');
system ($git, 'config', 'user.name', 'Masahiro Homma');
system ($git, 'add', '.');
system ($git, 'commit', '-am', "it's a test");

# Start testing
my $tmpdir = tempdir CLEANUP => 1;
chdir $tmpdir;
my $injector = OrePAN2::Injector->new(
    directory => '.',
);
$injector->inject("git+file://$gitrepo");

ok -f 'authors/id/D/DU/DUMMY/Acme-YakiniQ-0.01.tar.gz', "inject from git";

done_testing;
