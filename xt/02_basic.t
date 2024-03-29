use v5.16;
use warnings;

use Test::More;
use lib "xt/lib";
use Util;

subtest exclude => sub {
    my $guard = tempd;
    spew "use Hoge1; use File::pushd;" => "hello.pl";
    spew_pm "Hoge1", "lib";
    system("cpanm", "-nq", "--reinstall", "-Llocal", "File::pushd") == 0 or die;
    system("cpanm", "-nq", "--reinstall", "-Llocal", "Capture::Tiny") == 0 or die;

    subtest basic => sub {
        run "hello.pl", "--exclude", "Capture::Tiny";
        ok -f "hello.fatpack.pl";
        ok  contains("hello.fatpack.pl", "Hoge1");
        ok  contains("hello.fatpack.pl", "File::pushd");
        ok !contains("hello.fatpack.pl", "Capture::Tiny");
    };

    subtest abs_path => sub {
        my $r = run "hello.pl",
            "-d", "$guard/local",
            "-e", "Capture::Tiny",
            "-o", "abs_out";
        unlike $r->err, qr/WARN/;
        ok !contains("abs_out", "Capture::Tiny");
    };

    subtest relative_path => sub {
        mkdir "test";
        my $guard = pushd "test";
        my $r = run "../hello.pl",
            "-d", "../local",
            "-e", "Capture::Tiny",
            "-o", "relative_out";
        unlike $r->err, qr/WARN/;
        ok !contains("relative_out", "Capture::Tiny");
    };
};

subtest shebang => sub {
    my $guard = tempd;
    spew <<'...' => 'no_shebang';
1;
...
    spew <<'...' => 'shebang';
#!/usr/bin/perl
1;
...
    spew <<'...' => 'multi_shebang';
#!/bin/sh
exec perl -x $0 "$@"
#!perl
1;
...
    run "no_shebang";
    run "shebang";
    run "multi_shebang";

    my $fatpack_line = '# This chunk of stuff was generated by App::FatPacker. To find the original';

    my @lines;
    @lines = split /\n/, slurp "no_shebang.fatpack";
    is $lines[0], ''; # make sense?
    is $lines[1], $fatpack_line;

    @lines = split /\n/, slurp 'shebang.fatpack';
    is $lines[0], '#!/usr/bin/perl';
    is $lines[1], '';
    is $lines[2], $fatpack_line;

    @lines = split /\n/, slurp 'multi_shebang.fatpack';
    is $lines[0], '#!/bin/sh';
    is $lines[1], 'exec perl -x $0 "$@"';
    is $lines[2], '#!perl';
    is $lines[3], '';
    is $lines[4], $fatpack_line;
};

subtest custom_shebang => sub {
    my $guard = tempd;
    spew <<'...' => 'no_shebang';
1;
...
    spew <<'...' => 'shebang';
#!/usr/bin/perl
1;
...
    spew <<'...' => 'multi_shebang';
#!/bin/sh
exec perl -x $0 "$@"
#!perl
1;
...
    my $custom_shebang = <<'...';
#!/bin/sh
exec perl -x $0 "$@"
#!perl
...
    run '--shebang', $custom_shebang, "no_shebang";
    run '--shebang', $custom_shebang, "shebang";
    run '--shebang', '#!/usr/bin/env perl', "multi_shebang";

    my $fatpack_line = '# This chunk of stuff was generated by App::FatPacker. To find the original';

    my @lines;
    @lines = split /\n/, slurp "no_shebang.fatpack";
    is $lines[0], '#!/bin/sh';
    is $lines[1], 'exec perl -x $0 "$@"';
    is $lines[2], '#!perl';
    is $lines[3], '';
    is $lines[4], $fatpack_line;

    @lines = split /\n/, slurp 'shebang.fatpack';
    is $lines[0], '#!/bin/sh';
    is $lines[1], 'exec perl -x $0 "$@"';
    is $lines[2], '#!perl';
    is $lines[3], '';
    is $lines[4], $fatpack_line;

    @lines = split /\n/, slurp 'multi_shebang.fatpack';
    is $lines[0], '#!/usr/bin/env perl';
    is $lines[1], $fatpack_line;
};

done_testing;
