[![Build Status](https://travis-ci.org/shoichikaji/App-FatPacker-Simple.svg?branch=master)](https://travis-ci.org/shoichikaji/App-FatPacker-Simple)
# NAME

App::FatPacker::Simple - only fatpack a script

# SYNOPSIS

    > fatpack-simple script.pl

# DESCRIPTION

App::FatPacker::Simple or its frontend `fatpack-simple` helps you
fatpack a script when **you** understand the whole dependencies of it.

For tutorial, please look at [App::FatPacker::Simple::Tutorial](https://metacpan.org/pod/App::FatPacker::Simple::Tutorial).

# MOTIVATION

App::FatPacker::Simple is a subclass of [App::FatPacker](https://metacpan.org/pod/App::FatPacker).
Let me explain why I wrote this module.

[App::FatPacker](https://metacpan.org/pod/App::FatPacker) brings more portability to Perl, that is totally awesome.

As far as I understand, App::FatPacker does 3 things:
(a) trace dependencies for a script,
(b) collects dependencies to `fatlib` directory
and (c) fatpack the script with modules in `fatlib`.

As for (a), I often encountered problems. For example,
modules that I don't want to trace trace,
conversely, modules that I DO want to trace do not trace.
Moreover a module changes interfaces recently,
so we have to fatpack that module with new version, etc.
So I think if you author intend to fatpack a script,
**YOU** need to understand the whole dependencies of it.

As for (b), to locate modules in a directory, why don't you use
`carton` or `cpanm`?

So the rest is (c) to fatpack a script with modules in directories,
on which App::FatPacker::Simple concentrates.

That is, App::FatPacker::Simple only fatpacks a script with features:

- automatically perl-strip modules
- has option to exclude some modules

# SEE ALSO

[App::FatPacker](https://metacpan.org/pod/App::FatPacker)

[App::fatten](https://metacpan.org/pod/App::fatten)

[Perl::Strip](https://metacpan.org/pod/Perl::Strip)

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
