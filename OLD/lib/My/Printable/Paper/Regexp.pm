package My::Printable::Paper::Regexp;
use warnings;
use strict;
use v5.10.0;

use Exporter qw(import);
our %EXPORT_TAGS = (
    regexp => [
        '$RE_REAL',
        '$RE_NUMBER',
        '$RE_UNIT',
        '$RE_LENGTH',
        '$RE_FROM_EDGE',
        '$RE_DIMENSION',
        '$RE_RGBA',
        '$RE_RGBA_SEP',
        '$RE_COLOR_12BIT',
        '$RE_COLOR_24BIT',
        '$RE_COLOR_48BIT',
        '$RE_COLOR_CSS',
        '$RE_PP_MATCH',
    ],
    functions => [
        'matchNumber',
        'matchLength',
        'matchDimension',
        'matchPaperSize',
        'matchCSSColor',
    ],
);
our @EXPORT = (
    '$RE_PP_MATCH',
);
our @EXPORT_OK = (
    @{$EXPORT_TAGS{regexp}},
    @{$EXPORT_TAGS{functions}},
);

use Regexp::Common qw(number);

our $RE_REAL             = qr{$RE{num}{real}};
our $RE_NUMBER           = qr{(?:(${RE_REAL})(?:\s*[\-\+]\s*|\s+))?(${RE_REAL})(?:\s*/\s*(${RE_REAL}))?}x;
our $RE_UNIT             = qr{[[:alpha:]]+|%};
our $RE_LENGTH           = qr{${RE_NUMBER}(?:\s*(${RE_UNIT}))?};
our $RE_FROM_EDGE        = qr{from\s+(left|right|top|bottom)}i;
our $RE_DIMENSION        = qr{${RE_NUMBER}(?:\s*(${RE_UNIT}))?(?:\s+(?:${RE_FROM_EDGE}))?};
our $RE_PAPER_SIZE       = qr{$RE_LENGTH\s*[x\*]\s*$RE_LENGTH};

our $RE_PP_MATCH;

sub matchNumber {
    $RE_PP_MATCH = (shift // $_) =~ $RE_NUMBER ? {
        number2     => $1,
        number      => $2,
        denominator => $3,
    } : undef;
}

sub matchLength {
    $RE_PP_MATCH = (shift // $_) =~ $RE_LENGTH ? {
        number2     => $1,
        number      => $2,
        denominator => $3,
        unit        => $4,
    } : undef;
}

sub matchDimension {
    $RE_PP_MATCH = (shift // $_) =~ $RE_DIMENSION ? {
        number2     => $1,
        number      => $2,
        denominator => $3,
        unit        => $4,
        fromEdge    => $5,
    } : undef;
}

sub matchPaperSize {
    $RE_PP_MATCH = (shift // $_) =~ $RE_PAPER_SIZE ? {
        width => {
            number2     => $1,
            number      => $2,
            denominator => $3,
            unit        => $4,
        },
        height => {
            number2     => $5,
            number      => $6,
            denominator => $7,
            unit        => $8,
        },
    } : undef;
}

our $RE_COLOR_12BIT = qr{\#
                         ([[:xdigit:]])
                         ([[:xdigit:]])
                         ([[:xdigit:]])
                         ([[:xdigit:]])?}x;
our $RE_COLOR_24BIT = qr{\#
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})?}x;
our $RE_COLOR_48BIT = qr{\#
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})?}x;
our $RE_RGBA        = qr{${RE_NUMBER}%?};
our $RE_RGBA_SEP    = qr{(?:\s*,\s*|\s+)};
our $RE_COLOR_CSS   = qr{rgba?
                         \(
                         \s*
                         ($RE_RGBA)
                         $RE_RGBA_SEP
                         ($RE_RGBA)
                         $RE_RGBA_SEP
                         ($RE_RGBA)
                         (?:
                             $RE_RGBA_SEP
                             ($RE_RGBA)
                         )?
                         \s*
                         \)}x;

sub matchCSSColor {
    my $string = (shift // $_);
    if ($string =~ $RE_COLOR_CSS) {
        return $RE_PP_MATCH = {
            style => 'rgba',
            r => $1,
            g => $2,
            b => $3,
            a => $4,
        };
    } elsif ($string =~ $RE_COLOR_12BIT) {
        return $RE_PP_MATCH = {
            style => '12bit',
            r => $1,
            g => $2,
            b => $3,
            a => $4,
        };
    } elsif ($string =~ $RE_COLOR_24BIT) {
        return $RE_PP_MATCH = {
            style => '24bit',
            r => $1,
            g => $2,
            b => $3,
            a => $4,
        };
    } elsif ($string =~ $RE_COLOR_48BIT) {
        return $RE_PP_MATCH = {
            style => '48bit',
            r => $1,
            g => $2,
            b => $3,
            a => $4,
        };
    } else {
        return $RE_PP_MATCH = undef;
    }
}

1;
