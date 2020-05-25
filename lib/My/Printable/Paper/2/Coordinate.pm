package My::Printable::Paper::2::Coordinate;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Unit;
use My::Printable::Paper::2::Regexp qw($RE_COORDINATE parseMixedFraction);

use List::Util qw(any);

sub parse {
    my $value = shift;
    my %args = @_;
    my $axis = $args{axis};
    my $paper = $args{paper};
    my $defaultUnit = $args{defaultUnit};

    if (!defined $value) {
        die("value must be specified");
    }
    if (defined $axis && ($axis ne 'x' && $axis ne 'y')) {
        die("axis must be 'x', 'y', or undef");
    }
    if ($value !~ m{^\s*$RE_COORDINATE\s*$}) {
        die("invalid coordinate '$value'");
    }
    my $unit     = $+{unit};
    my $side     = $+{side};
    my $boundary = $+{boundary} // 'edge'; # side, edge, clip
    my $resultPt = parseMixedFraction($+{mixed}, $+{numer}, $+{denom});
    if (defined $unit) {
        $resultPt *= My::Printable::Paper::2::Unit::parse($unit, axis => $axis, paper => $paper);
    } else {
        if (defined $defaultUnit) {
            $resultPt *= My::Printable::Paper::2::Coordinate::parse($defaultUnit, axis => $axis, paper => $paper);
        }
    }
    if (defined $side) {
        if (!defined $paper) {
            die("cannot specify side without paper object");
        }
        my $sizePt;
        if (!defined $axis) {
            die("axis must be 'x' or 'y' to use side-based coordinate");
        } elsif ($axis eq 'x') {
            $sizePt = My::Printable::Paper::2::Coordinate::parse($paper->width, axis => 'x', paper => $paper);
        } elsif ($axis eq 'y') {
            $sizePt = My::Printable::Paper::2::Coordinate::parse($paper->height, axis => 'y', paper => $paper);
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
