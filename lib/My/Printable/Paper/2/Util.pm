package My::Printable::Paper::2::Util;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Const qw(:tolerance);

use parent 'Exporter';
our %EXPORT_TAGS = (
    snap => [qw(snapcmp snapnum snapeq snapne snaplt snapgt snaple snapge
                snapneg snappos)],
    stroke => [qw(strokeDashArray strokeDashOffset)],
);
our @EXPORT = (
);
our @EXPORT_OK = (
    (map { @$_ } values %EXPORT_TAGS),
);

use List::Util qw(all);

# return 0 if $a is close enough to $b;
# return -1 or 1 if $a is less or greater than $b.
sub snapcmp {
    my ($a, $b, $tolerance) = @_;
    $a //= 0;
    $b //= 0;
    $tolerance //= TOLERANCE;

    return 0 if abs($a - $b) < $tolerance;
    return -1 if $a < $b;
    return 1 if $a > $b;
    return 0;
}

sub snapeq {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) == 0;
}

# return $b if $a is close enough to $b;
# return $a otherwise.
sub snapnum {
    my ($a, $b, $tolerance) = @_;
    $a //= 0;
    $b //= 0;
    $tolerance //= TOLERANCE;

    return $b if abs($a - $b) < $tolerance;
    return $a;
}

sub snaplt {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) < 0;
}
sub snapgt {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) > 0;
}
sub snaple {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) <= 0;
}
sub snapge {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) >= 0;
}
sub snapne {
    my ($a, $b, $tolerance) = @_;
    return snapcmp($a, $b, $tolerance) != 0;
}
sub snapneg {
    my ($a, $tolerance) = @_;
    return snapcmp($a, 0, $tolerance) < 0;
}
sub snappos {
    my ($a, $tolerance) = @_;
    return snapcmp($a, 0, $tolerance) > 0;
}

sub strokeDashArray {
    my %args = @_;
    my $paper = $args{paper};
    my $axis = $args{axis};
    my $dashLength  = $args{dashLength};
    my $dashSpacing = $args{dashSpacing};

    return undef if !defined $dashLength && !defined $dashSpacing;

    if (defined $paper && defined $axis) {
        foreach my $d ($dashLength, $dashSpacing) {
            $d = $paper->coordinate($d, $axis) if defined $d;
        }
    }
    if (defined $dashSpacing && !defined $dashLength) {
        $dashLength = $dashSpacing / 2;
    } elsif (defined $dashLength && !defined $dashSpacing) {
        $dashSpacing = $dashLength * 2;
    }

    if ($dashLength < SVG_STROKE_DASH_TOLERANCE) {
        $dashLength = SVG_STROKE_DASH_TOLERANCE;
    }
    return sprintf('%.3f %.3f', $dashLength, $dashSpacing - $dashLength);
}

sub strokeDashOffset {
    my %args = @_;
    my $paper = $args{paper};
    my $axis = $args{axis};
    my $dashLength    = $args{dashLength};
    my $dashSpacing   = $args{dashSpacing};
    my $dashLineStart = $args{dashLineStart} // 0;
    my $dashCenterAt  = $args{dashCenterAt} // 0;

    return undef if !defined $dashLength && !defined $dashSpacing;

    if (defined $paper && defined $axis) {
        foreach my $d ($dashLength, $dashSpacing) {
            $d = $paper->coordinate($d, $axis) if defined $d;
        }
    }
    if (defined $dashSpacing && !defined $dashLength) {
        $dashLength = $dashSpacing / 2;
    } elsif (defined $dashLength && !defined $dashSpacing) {
        $dashSpacing = $dashLength * 2;
    }

    my $lineLength;
    my ($x1, $x2, $y1, $y2) = @args{qw(x1 x2 y1 y2)};
    if (all { defined $_ } ($x1, $x2, $y1, $y2)) {
        $lineLength = sqrt(($x2 - $x1) ** 2 + ($y2 - $y1) ** 2);
    }

    if ($dashLength < SVG_STROKE_DASH_TOLERANCE) {
        $dashLength = SVG_STROKE_DASH_TOLERANCE;
    }
    return sprintf('%.3f', $dashLength / 2 + $dashLineStart - $dashCenterAt);
}

1;
