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
    my $mixed    = 0 + ($+{mixed} // 0);
    my $numer    = 0 + $+{numer};
    my $denom    = 0 + ($+{denom} // 1);
    my $unit     = $+{unit};
    my $side     = $+{side};
    my $boundary = $+{boundary} // 'edge'; # side, edge, clip

    my $resultPt = $mixed + $numer / $denom;
    if (defined $unit) {
        $resultPt *= My::Printable::Paper::2::Unit::parse($unit, $axis, $paper);
    }
    if (defined $side) {
        if (!defined $paper) {
            die("cannot specify side without paper object");
        }
        my $sizePt;
        if (!defined $axis) {
            die("axis must be 'x' or 'y' to use side-based coordinate");
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
        my $clipStart = $axis eq 'x' ? $paper->xx('clipLeft') : $paper->yy('clipTop');
        my $clipEnd   = $axis eq 'x' ? $paper->xx('clipTop')  : $paper->yy('clipBottom');
        if (any { $_ eq $side } qw(top left start begin)) {
            if ($boundary eq 'clip') {
                $resultPt = $resultPt + $clipStart;
            }
            # do nothing
        } elsif (any { $_ eq $side } qw(bottom right stop end)) {
            if ($boundary eq 'clip') {
                $resultPt = $sizePt - $resultPt - $clipEnd;
            } else {
                $resultPt = $sizePt - $resultPt;
            }
        } else {
            die("invalid side '$side'");
        }
    }
    return $resultPt;
}

1;
