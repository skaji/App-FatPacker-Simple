package App::FatPacker::Simple;
use strict;
use warnings;
use utf8;
use App::cpanminus::fatscript;
use Config;
use Cwd 'cwd';
use File::Basename 'basename';
use File::Find 'find';
use File::Spec::Functions 'catdir';
use File::Spec::Unix;
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case);
use Perl::Strip;
use Pod::Usage 'pod2usage';

our $VERSION = '0.01';

use parent 'App::FatPacker';

our $IGNORE_FILE = [
    qr/\.pod$/,
    qr/^\.packlist$/,
    qr/^MYMETA\.json$/,
    qr/^install\.json$/,
];

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{perl_strip} = Perl::Strip->new;
    $self;
}

sub parse_options {
    my $self = shift;
    local @ARGV = @_;
    GetOptions
        "output|o=s"  => \(my $output),
        "quiet|q"     => \(my $quiet),
        "dir|d=s"     => \(my $dir = 'ext,extlib,lib,fatpack,local'),
        "help|h"      => sub { pod2usage(0) },
        "exclude|e=s" => \(my $exclude),
        "strict|s"    => \(my $strict),
        "color!"      => \(my $color = 1),
    or pod2usage(1);
    $self->{script} = shift @ARGV
        or do { warn "Missing scirpt.\n"; pod2usage(1) };
    $self->{dir}    = $self->build_dir($dir);
    $self->{output} = $output;
    $self->{quiet}  = $quiet;
    $self->{strict} = $strict;
    $self->{color}  = $color;
    $self->{exclude} = [];
    if ($exclude) {
        my $cpanm = App::FatPacker::Simple::cpanm->new;
        my $inc = [map {("$_/$Config{archname}", $_)} @{$self->{dir}}];
        for my $e (split /,/, $exclude) {
            my ($metadata, $packlist) = $cpanm->packlists_containing($e, $inc);
            if ($packlist) {
                push @{$self->{exclude}}, $cpanm->unpack_packlist($packlist);
            } else {
                $self->warning("Missing $e in $dir");
            }
        }
    }
    $self;
}

sub warning {
    my ($self, $msg) = @_;
    chomp $msg;
    my $color = $self->{color}
              ? sub { "\e[31m$_[0]\e[m", "\n" }
              : sub { "$_[0]\n" };
    if ($self->{strict}) {
        die $color->("=> ERROR $msg");
    } elsif (!$self->{quiet}) {
        warn $color->("=> WARN $msg");
    }
}

sub debug {
    my ($self, $msg) = @_;
    chomp $msg;
    if (!$self->{quiet}) {
        warn "-> $msg\n";
    }
}

{
    package App::FatPacker::Simple::cpanm;
    use parent 'App::cpanminus::script';
    # for relocatable perl patch
    sub unpack_packlist {
        my ($self, $packlist) = @_;
        open my $fh, '<', $packlist or die "$packlist: $!";
        map { chomp; s/\s+relocate_as=.*//; $_ } <$fh>;
    }
}

sub output_filename {
    my $self = shift;
    return $self->{output} if $self->{output};

    my $script = basename $self->{script};
    my ($suffix, @other) = reverse split /\./, $script;
    if (!@other) {
        "$script.fatpack";
    } else {
        unshift @other, "fatpack";
        join ".", reverse(@other), $suffix;
    }
}

sub run {
    my $self = shift;
    my $fatpacked = $self->fatpack_file($self->{script});
    open my $fh, ">", $self->output_filename
        or die "Cannot open '@{[$self->output_filename]}': $!\n";
    print {$fh} $fatpacked;
    close $fh;
    my $mode = (stat $self->{script})[2];
    chmod $mode, $self->output_filename;
}

sub load_file {
    my ($self, $file, $dir) = @_;

    my $content = do {
        open my $fh, "<", $file or die "Cannot open '$file': $!\n";
        local $/; <$fh>;
    };
    my $relative = File::Spec::Unix->abs2rel($file, $dir);
    $self->debug("perl-strip $relative");
    return $self->{perl_strip}->strip($content);
}

sub collect_files {
    my ($self, $dir, $files) = @_;
    find sub {
        return unless -f $_;
        for my $ignore (@$IGNORE_FILE) {
            $_ =~ $ignore and return;
        }
        if ($File::Find::name =~ m!$dir/$Config{archname}!) {
            return;
        }
        my $relative = File::Spec::Unix->abs2rel($File::Find::name, $dir);
        for my $exclude (@{$self->{exclude}}) {
            if ($File::Find::name eq $exclude) {
                $self->debug("exclude $relative");
                return;
            }
        }
        if (!/\.pm$/) {
            $self->warning("skip non pm file $relative");
            return;
        }
        $files->{$relative} = $self->load_file($File::Find::name, $dir);
    }, $dir;
}

sub build_dir {
    my ($self, $dir_string) = @_;
    my $cwd = cwd;
    my @dir;
    for my $d (grep -d, map { catdir($cwd, $_) } split /,/, $dir_string) {
        my $try = catdir($d, "lib/perl5");
        if (-d $try) {
            push @dir, $try, catdir($try, $Config{archname});
        } else {
            push @dir, $d, catdir($d, $Config{archname});
        }
    }
    return [ grep -d, @dir ];
}


sub collect_dirs {
    @{ shift->{dir} };
}


1;
__END__

=encoding utf-8

=head1 NAME

App::FatPacker::Simple - fatpack a script

=head1 SYNOPSIS

    > fatpack-simple script.pl

=head1 DESCRIPTION

App::FatPacker::Simple helps you fatpack a script.

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

