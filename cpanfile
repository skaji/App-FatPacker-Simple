requires 'perl', '5.008005';
requires 'App::FatPacker';
requires 'Perl::Strip';
requires 'Distribution::Metadata';

on test => sub {
    requires 'File::pushd';
    requires 'Capture::Tiny';
    requires 'Test::More', '0.98';
};

