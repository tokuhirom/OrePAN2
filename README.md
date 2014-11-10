# NAME

OrePAN2 - Yet another DarkPAN manager.

# DESCRIPTION

You can create your own Perl module archive with OrePAN2!
It's very simple and useful.

- 1. Inject tarballs from git repo or archive file via orepan2-inject.
- 2. Make 02packages.details.txt.gz via orepan2-indexer.

# TUTORIAL

Download a tar ball from CPAN.

    % orepan2-inject http://cpan.metacpan.org/authors/id/M/MA/MAHITO/Acme-Hoge-0.03.tar.gz /path/to/darkpan/

Create 02packages.details.txt!

    % orepan2-indexer /path/to/darkpan/

Then you can install Acme::Hoge from DarkPAN!

    % cpanm --mirror-only --mirror=file:///path/to/darkpan/ Acme::Hoge

It's pretty easy!

# What's the difference between OrePAN 2 and OrePAN1?

- OrePAN2 has a cleaner interface.
- OrePAN2 provides an OO-ish interface

    You can use OrePAN2 as a library.

- OrePAN2 uses modern modules like [Parse::LocalDistribution](https://metacpan.org/pod/Parse::LocalDistribution).

    OrePAN1 did a lot of heavy lifting on its own. OrePAN2 delegates most tasks to other CPAN modules.

- OrePAN2 is active project

    OrePAN1 is now in maintenance mode, but OrePAN2 is still under active development.

# SEE ALSO

[OrePAN2::Server](https://metacpan.org/pod/OrePAN2::Server)

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
