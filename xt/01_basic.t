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
    run "hello.pl", "--exclude", "Capture::Tiny";
    ok -f "hello.fatpack.pl";
    ok  contains("hello.fatpack.pl", "Hoge1");
    ok  contains("hello.fatpack.pl", "File::pushd");
    ok !contains("hello.fatpack.pl", "Capture::Tiny");
};

done_testing;
