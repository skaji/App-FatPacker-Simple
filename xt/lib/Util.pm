package Util;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Capture::Tiny qw(capture);
use Cwd 'abs_path';
use Exporter 'import';
use File::Basename 'dirname';
use File::Path 'mkpath';
use File::Spec;
use File::pushd qw(pushd tempd);

our @EXPORT = qw(run spew spew_pm slurp contains pushd tempd);

my $base = abs_path( File::Spec->catdir( dirname(__FILE__), "..", "..") );

package Result {
    sub new ($class, $out, $err, $exit) {
        bless { exit => $exit, out => $out, err => $err }, $class;
    }
    sub success ($self) {
        $self->{exit} == 0;
    }
    sub out ($self) {
        my $out = $self->{out};
        wantarray ? ( split /\n/, $out ) : $out;
    }
    sub err ($self) {
        my $err = $self->{err};
        wantarray ? ( split /\n/, $err ) : $err;
    }
}

sub run (@argv) {
    my ($out, $err, $exit) = capture {
        # your responsibility :-)
        # local $ENV{PERL5LIB};
        # local $ENV{PERL5OPT};
        system $^X, "-I$base/lib", "$base/script/fatpack-simple", @argv;
    };
    Result->new($out, $err, $exit);
}

sub spew ($content, $file) {
    my $dir = dirname($file);
    mkpath $dir unless -d $dir;
    open my $fh, ">", $file or die "open $file: $!";
    print {$fh} $content;
}

sub slurp ($file) {
    open my $fh, "<", $file or die "open $file: $!";
    local $/; <$fh>;
}

sub spew_pm ($package, $dir) {
    my $pm = $package;
    $pm =~ s{::}{/}; $pm .= ".pm";
    spew "use $package; 1; # this is comment" => "$dir/$pm";
}

sub contains ($file, $package) {
    my $content = slurp $file;
    my $pm = $package;
    $pm =~ s{::}{/}; $pm .= ".pm";
    index( $content, qq(\$fatpacked{"$pm"}) ) != -1;
}

1;
