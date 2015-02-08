use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

subtest basic => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    chmod 0755, "hello.pl";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    ok system($^X, "-c", "hello.fatpack.pl") == 0;
    ok -x "hello.fatpack.pl";

    run "hello.pl", "--output", "foo.pl";
    ok -f "foo.pl";

    spew "1" => "output-test";
    run "output-test";
    ok -f "output-test.fatpack";
};

subtest dir => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib";
    spew_pm "Hoge3", "local";
    spew_pm "Hoge4", "fatlib";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    for my $i (1..4) {
        ok contains("hello.fatpack.pl", "Hoge$i");
    }

    spew_pm "Hoge5", "other";
    run "hello.pl", "--dir", "other";
    for my $i (1..4) {
        ok !contains("hello.fatpack.pl", "Hoge$i");
    }
    ok contains("hello.fatpack.pl", "Hoge5");
};

subtest local_lib => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew_pm "Hoge1", "lib";
    spew_pm "Hoge2", "extlib/lib/perl5";
    spew_pm "Hoge3", "local/lib/perl5";
    run "hello.pl";
    ok -f "hello.fatpack.pl";
    for my $i (1..3) {
        ok contains("hello.fatpack.pl", "Hoge$i");
    }
};

subtest non_pm => sub {
    my $guard = tempd;
    spew 1 => "hello.pl";
    spew 1 => "lib/foo.so";
    my $r = run "hello.pl";
    ok $r->success;
    like $r->err, qr/WARN/;

    $r = run "hello.pl", "--strict", "--output", "foo.pl";
    ok !$r->success;
    like $r->err, qr/ERROR/;
    ok !-f "foo.pl";
};

done_testing;
