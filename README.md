# NAME

fatpack-simple - only fatpack a script

# SYNOPSIS

    > fatpack-simple [OPTIONS] SCRIPT

    Options:
    -d, --dir DIRECTORIES   where pm files to be fatpacked are.
                            default: lib,ext,extlib,local,fatlib
    -o, --output OUTPUT     output filename
    -e, --exclude MODULES   modules not to be fatpacked
    -s, --strict            turn on strict mode
    -q, --quiet             be quiet
        --color             color output, default: on
    -h, --help              show this help

    Examples:
    > fatpack-simple my-script.pl
    > fatpack-simple --dir deps,my-ext --out hoge.fatpacked.pl hoge.pl
    > fatpack-simple --exclude Module::Build,List::MoreUtils --strict script.pl

# DESCRIPTION

`fatpack-simple` helps you fatpack your script
when you understand the whole dependencies of your scirpt.

## HOW TO FATPACK my-script.pl

`my-script.pl` may use your perl module in `lib` directory.

First install external dependencies of `my-script.pl` to `local` dir:

    # if extenal dependencies declared in cpanfile
    > carton install
    # or manually
    > cpanm -Llocal Foo Hoge
    # or may requires --reintall option
    > cpanm -llocal --reinstall HTTP::Tiny

Now the whole dependencies are in `lib` and `local` directories.
Execute `fatpack-simple`, and you get `my-script.fatpack.pl`:

    > fatpack-simple my-script.pl
    # get my-script.fatpack.pl

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
