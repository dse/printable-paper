package My::RuledPaper::Parse::PaperSize;
use warnings;
use strict;

# example:
#     letter
#     8.5inx11in
#     210mm*297mm
#     5.5in,8.5in

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(parsePaperSize);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK]
);

use lib "../../..";
use My::RuledPaper::Constants qw(:all);
use My::RuledPaper::Parse::Dimension qw(parseDimension $REGEX_DIMEN);

our %SIZES;
BEGIN {
    %SIZES = (
        letter     => [8.5 * IN, 11 * IN],
        halfletter => [5.5 * IN, 8.5 * IN],
        a4         => [250 / sqrt(sqrt(2)) * MM, 250 * sqrt(sqrt(2)) * MM],
        a5         => [125 * sqrt(sqrt(2)) * MM, 250 / sqrt(sqrt(2)) * MM],
    );
}

our $REGEX_NAMED_PAPER_SIZE;
our $REGEX_NUMERIC_PAPER_SIZE;
our $REGEX_PAPER_SIZE;
BEGIN {
    $REGEX_NAMED_PAPER_SIZE = join('|', map { quotemeta } keys %SIZES);
    $REGEX_NAMED_PAPER_SIZE = qr{(?<namedSize>${REGEX_NAMED_PAPER_SIZE})};
    $REGEX_NUMERIC_PAPER_SIZE = qr{(?<width>${REGEX_DIMEN})[x*,](?<height>${REGEX_DIMEN})}x;
    $REGEX_PAPER_SIZE = qr{(?:${REGEX_NUMERIC_PAPER_SIZE}|${REGEX_NAMED_PAPER_SIZE})}x;
}

sub parsePaperSize {
    my ($size) = @_;
    $size =~ s{[-\s]+}{}g;
    $size = lc($size);
    if ($size !~ m{^${REGEX_PAPER_SIZE}$}) {
        die("invalid paper size: $size");
    }
    my ($namedSize, $width, $height) = ($+{namedSize}, $+{width}, $+{height});
    if (defined $namedSize) {
        my $result = $SIZES{$namedSize};
        die("invalid paper size $size") if !defined $result;
        return @$result if wantarray;
        return [@$result];
    }
    if (defined $width && defined $height) {
        my @size = (parseDimension($width), parseDimension($height));
        return @size if wantarray;
        return [@size];
    }
    die("invalid paper size: $size");
}

1;
