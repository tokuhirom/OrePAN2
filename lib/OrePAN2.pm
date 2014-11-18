package OrePAN2;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.32";

1;
__END__

=encoding utf-8

=for stopwords DarkPAN orepan2-inject orepan2-indexer darkpan OrePAN1 OrePAN

=head1 NAME

OrePAN2 - Yet another DarkPAN manager.

=head1 DESCRIPTION

You can create your own Perl module archive with OrePAN2!
It's very simple and useful.

=over 4

=item 1. Inject tarballs from git repo or archive file via orepan2-inject.

=item 2. Make 02packages.details.txt.gz via orepan2-indexer.

=back

=head1 TUTORIAL

Download a tar ball from CPAN.

    % orepan2-inject http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz /path/to/darkpan/

Create 02packages.details.txt!

    % orepan2-indexer /path/to/darkpan/

Then you can install Acme::Hoge from DarkPAN!

    % cpanm --mirror-only --mirror=file:///path/to/darkpan/ Acme::Hoge

It's pretty easy!

=head1 What's the difference between OrePAN 2 and OrePAN1?

=over 4

=item OrePAN2 has a cleaner interface.

=item OrePAN2 provides an OO-ish interface

You can use OrePAN2 as a library.

=item OrePAN2 uses modern modules like L<Parse::LocalDistribution>.

OrePAN1 did a lot of heavy lifting on its own. OrePAN2 delegates most tasks to other CPAN modules.

=item OrePAN2 is active project

OrePAN1 is now in maintenance mode, but OrePAN2 is still under active development.

=back

=head1 SEE ALSO

L<OrePAN2::Server>

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

