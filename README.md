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

# What's difference between OrePAN1?

- OrePAN2 has more clean and sane interface.
- OrePAN2 provides OO-ish interface

    You can use OrePAN2 as a library.

- OrePAN2 uses modern modules like [Parse::LocalDistribution](https://metacpan.org/pod/Parse::LocalDistribution).

    OrePAN1 coded a lot of things by itself. OrePAN2 delegates most of things to other CPAN modules.

- OrePAN2 is active project

    OrePAN1 is now in maintenance phase. But OrePAN2 is still in actively development.

# SEE ALSO

[OrePAN2::Server](https://metacpan.org/pod/OrePAN2::Server)

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
