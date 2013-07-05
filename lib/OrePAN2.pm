package OrePAN2;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.07";

1;
__END__

=encoding utf-8

=for stopwords DarkPAN orepan2-inject orepan2-indexer darkpan

=head1 NAME

OrePAN2 - Yet another DarkPAN manager.

=head1 DESCRIPTION

You can create your own perl module archive with OrePAN2!
It's very simple and useful.

=over 4

=item 1. Inject tar balls from git repo or archive file by orepan2-inject.

=item 2. Make 02packages.details.txt.gz by orepan2-indexer.

=back

=head1 TUTORIAL

Download tar ball from CPAN.

    % orepan2-inject http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz /tmp/darkpan

Create 02packages.details.txt!

    % orepan2-indexer /tmp/darkpan/

Then you can install Acme::Hoge from darkpan!

    % cpanm --mirror-only --mirror=file:///tmp/darkpan/ Acme::Hoge

It's pretty easy!

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

