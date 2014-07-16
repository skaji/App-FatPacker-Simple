package App::FatPacker::Simple;
use strict;
use warnings;
use utf8;
use Cwd 'cwd';
use File::Basename 'basename';
use File::Spec::Functions 'catdir';
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case);
use Perl::Strip;
use Pod::Usage 'pod2usage';
use File::Find 'find';

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
        "output|o=s" => \(my $output),
        "quiet|q"    => \(my $quiet),
        "dir|d=s"    => \(my $dir = 'ext,extlib,lib,fatpack,local'),
        "help|h"     => sub { pod2usage(0) },
    or pod2usage(1);
    $self->{script} = shift @ARGV
        or do { warn "Missing scirpt.\n"; pod2usage(1) };
    $self->{dir}    = [split /,/, $dir];
    $self->{output} = $output;
    $self->{quiet}  = $quiet;
    $self;
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
    my ($self, $file) = @_;

    my $content = do {
        open my $fh, "<", $file or die "Cannot open '$file': $!\n";
        local $/; <$fh>;
    };
    unless ($self->{quiet}) {
        my $pm_name = $file;
        $pm_name =~ s{.*?lib/(perl5/)?}{};
        warn "-> Perl::Strip $pm_name ...\n";
    }
    $self->{perl_strip}->strip($content);
}

sub collect_files {
  my ($self, $dir, $files) = @_;
  find(sub {
    return unless -f $_;
    for my $ignore (@$IGNORE_FILE) {
        $_ =~ $ignore and return;
    }
    !/\.pm$/ and warn "File ${File::Find::name} isn't a .pm file - can't pack this -- if you hoped we were going to, things may not be what you expected later\n" and return;
    $files->{File::Spec::Unix->abs2rel($File::Find::name,$dir)} =
      $self->load_file($File::Find::name);
  }, $dir);
}


sub collect_dirs {
    my $self = shift;
    my $cwd = cwd;
    my @dir;
    for my $d (grep -d, map { catdir($cwd, $_) } @{ $self->{dir} || [] }) {
        my $try = catdir($d, "lib/perl5");
        if (-d $try) {
            push @dir, $try;
        } else {
            push @dir, $d;
        }
    }
    return @dir;
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

