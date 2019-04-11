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
);
our @EXPORT = (
);
our @EXPORT_OK = (
    (map { @$_ } values %EXPORT_TAGS),
);

use Regexp::Common qw(number);

our $RE_UNIT = qr{[[:alpha:]]*|%|\'|\"}xi;

our $RE_COORDINATE = qr{^
                        \s*
                        (?:
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
                        )?
                        \s*
                        $}xi;

our $RE_PAPERSIZE = qr{^
                       \s*
                       (?:
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
                       (?:
                           x|\*
                       )
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
                       )?
                       \s*
                       $}xi;

1;
