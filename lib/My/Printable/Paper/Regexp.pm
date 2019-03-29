package My::Printable::Paper::Regexp;
use warnings;
use strict;
use v5.10.0;

use Exporter qw(import);
our %EXPORT_TAGS = (
    regexp => [
        '$RE_NUMBER',
        '$RE_FRACTION',
        '$RE_UNIT',
        '$RE_LENGTH',
        '$RE_RGBA',
        '$RE_RGBA_SEP',
        '$RE_COLOR_12BIT',
        '$RE_COLOR_24BIT',
        '$RE_COLOR_48BIT',
        '$RE_COLOR_CSS',
    ],
);
our @EXPORT = ();
our @EXPORT_OK = (@{$EXPORT_TAGS{regexp}});

use Regexp::Common qw(number);

our $RE_NUMBER   = qr{$RE{num}{real}};
our $RE_FRACTION = qr{($RE_NUMBER)(?:\s*/\s*($RE_NUMBER))?};
our $RE_UNIT     = qr{[[:alpha:]]+|%};
our $RE_LENGTH   = qr{${RE_NUMBER}(?:\s*(${RE_UNIT}))?};
our $RE_RGBA     = qr{${RE_NUMBER}%?};
our $RE_RGBA_SEP = qr{(?:\s*,\s*|\s+)};

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

1;
