package My::RuledPaper::Parse::Dimension;
use warnings;
use strict;

# example:
#     5mm
#     1/2in

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw($REGEX_FLOAT
                    $REGEX_FRAC
                    $REGEX_UNIT
                    $REGEX_DIMEN
                    parseDimension);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK]
);

use lib "../../..";
use My::RuledPaper::Constants qw(:all);

our %UNITS;
BEGIN {
    %UNITS = (
        mm => MM,
        in => IN,
        pt => PT,
        cm => CM,
        pc => PC,
        px => PX,
    );
}

our $REGEX_FLOAT;
our $REGEX_FRAC;
our $REGEX_UNIT;
our $REGEX_DIMEN;
BEGIN {
    $REGEX_FLOAT = qr{(?:
                          [-+]?
                          (?:\d+(_+\d+)?(?:\.(?:\d+(_+\d+)?)?)?|\.\d+(_+\d+)?)
                          (?:[Ee][-+]?\d+)?
                      )}x;
    $REGEX_FRAC = qr{(?<numer>${REGEX_FLOAT})(?:/(?<denom>${REGEX_FLOAT}))?}x;
    $REGEX_UNIT = join('|', map { quotemeta } keys %UNITS);
    $REGEX_UNIT = qr{(?<unit>${REGEX_UNIT})};
    $REGEX_DIMEN = qr{(?:${REGEX_FRAC})(?:${REGEX_UNIT})};
}

sub parseDimension {
    my ($dimen) = @_;
    $dimen =~ s{[\s_]+}{}g;
    if ($dimen =~ qr{^${REGEX_DIMEN}$}) {
        return (0 + $+{numer}) / ($+{denom} // 1) * $UNITS{lc($+{unit})};
    } else {
        die("invalid dimension: $dimen");
    }
}

1;
