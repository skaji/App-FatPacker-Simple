use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

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

done_testing;
