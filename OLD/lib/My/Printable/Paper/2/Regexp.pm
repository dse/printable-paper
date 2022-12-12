package My::Printable::Paper::2::Regexp;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use parent 'Exporter';
our %EXPORT_TAGS = (
    regexp => [
        '$RE_COORDINATE',
        '$RE_PAPERSIZE',
        '$RE_UNIT',
    ],
    sub => [
        'parseMixedFraction',
    ],
);
our @EXPORT = (
);
our @EXPORT_OK = (
    (map { @$_ } values %EXPORT_TAGS),
);

use Regexp::Common qw(number);

our $RE_UNIT = qr{[[:alpha:]]+|%|\'|\"}xi;

our $RE_COORDINATE = qr{(?:
                            (?<mixed>$RE{num}{real})
                            \s*
                            (?:[\+\-])
                            \s*
                        )?
                        (?<numer>$RE{num}{real})
                        (?:
                            \s*
                            /
                            \s*
                            (?<denom>$RE{num}{real})
                        )?
                        (?:
                            \s*
                            (?<unit>$RE_UNIT)
                        )?
                        (?:
                            (?:
                                \s+
                                from
                            )?
                            \s+
                            (?<side>top|bottom|left|right|start|begin|stop|end)
                            (?:
                                \s+
                                (?<boundary>side|edge|clip)
                                (?:
                                    \s+
                                    boundary
                                )?
                            )?
                        )?}xi;

our $RE_PAPERSIZE = qr{(?:
                           (?<mixed1>$RE{num}{real})
                           \s*
                           (?:[\+\-])
                           \s*
                       )?
                       (?<numer1>$RE{num}{real})
                       (?:
                           \s*
                           /
                           \s*
                           (?<denom1>$RE{num}{real})
                       )?
                       (?:
                           \s*
                           (?<unit1>$RE_UNIT)
                       )?
                       \s*
                       (?:x|\*)
                       \s*
                       (?:
                           (?<mixed2>$RE{num}{real})
                           \s*
                           (?:[\+\-])
                           \s*
                       )?
                       (?<numer2>$RE{num}{real})
                       (?:
                           \s*
                           /
                           \s*
                           (?<denom2>$RE{num}{real})
                       )?
                       (?:
                           \s*
                           (?<unit2>$RE_UNIT)
                       )?}xi;

sub parseMixedFraction {
    my ($mixed, $numer, $denom) = @_;
    $mixed //= '0';
    $denom //= '1';
    my $mixedSign = ($mixed =~ m{^\-}) ? -1 : 1; # '-0' is negative, heh
    $mixed = 0 + $mixed;
    $numer = 0 + $numer;
    $denom = 0 + $denom;
    return $mixed + $numer * $mixedSign / $denom;
}

1;
