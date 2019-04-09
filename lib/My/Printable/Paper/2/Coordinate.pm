package My::Printable::Paper::2::Coordinate;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Unit;

use Regexp::Common qw(number);

our $RE_COORDINATE;
INIT {
    $RE_COORDINATE = qr{^
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
                            (?<unit>[[:alpha:]]*|%|\'|\")
                        )?
                        (?:
                            (?:
                                \s+
                                from
                            )?
                            \s+
                            (?<edge>top|bottom|left|right|start|begin|stop|end)
                            (?:
                                \s+
                                (?:side|edge)
                            )?
                        )?
                        \s*
                        $}xi;
}

use List::Util qw(any);

sub parse {
    my $value = shift;
    my $axis = shift;
    my $paper = shift;

    if (!defined $value) {
        die("value must be specified");
    }
    if (defined $axis && ($axis ne 'x' && $axis ne 'y')) {
        die("axis must be 'x', 'y', or undef");
    }
    if ($value !~ $RE_COORDINATE) {
        die("invalid coordinate '$value'");
    }
    my $mixed = 0 + ($+{mixed} // 0);
    my $numer = 0 + $+{numer};
    my $denom = 0 + ($+{denom} // 1);
    my $unit  = $+{unit};
    my $edge  = $+{edge};

    my $resultPt = $mixed + $numer / $denom;
    if (defined $unit) {
        $resultPt *= My::Printable::Paper::2::Unit::parse($unit, $axis, $paper);
    }
    if (defined $edge) {
        if (!defined $paper) {
            die("cannot specify edge without paper object");
        }
        my $sizePt;
        if (!defined $axis) {
            die("axis must be 'x' or 'y' to use edge-based coordinate");
        } elsif ($axis eq 'x') {
            $sizePt = My::Printable::Paper::2::Coordinate::parse(
                $paper->width, 'x', $paper
            );
        } elsif ($axis eq 'y') {
            $sizePt = My::Printable::Paper::2::Coordinate::parse(
                $paper->height, 'y', $paper
            );
        } else {
            die("invalid axis '$axis'");
        }
        if (any { $_ eq $edge } qw(top left start begin)) {
            # do nothing
        } elsif (any { $_ eq $edge } qw(bottom right stop end)) {
            $resultPt = $sizePt - $resultPt;
        } else {
            die("invalid edge '$edge'");
        }
    }
    return $resultPt;
}

1;
