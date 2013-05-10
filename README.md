# NAME

OrePAN2 - Yet another DarkPAN manager.

# DESCRIPTION

You can create your own perl module archive with OrePAN2!
It's very simple and useful.

1. Inject tar balls from git repo or archive file by orepan2-inject.
2. Make 02packages.details.txt.gz by orepan2-indexer.

# TUTORIAL

Download tar ball from CPAN.

    % orepan2-inject http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz /tmp/darkpan

Create 02packages.details.txt!

    % orepan2-indexer /tmp/darkpan/

Then you can install Acme::Hoge from darkpan!

    % cpanm --mirror-only --mirror=file:///tmp/darkpan/ Acme::Hoge

It's pretty easy!

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
