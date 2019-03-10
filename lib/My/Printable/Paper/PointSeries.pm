package My::Printable::Paper::PointSeries;
use warnings;
use strict;
use v5.10.0;

use POSIX qw(trunc round);

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:around :const :trigger snapcmp snapnum);

use Moo;

has startPoint     => (is => 'rw', trigger => triggerUnit('startPoint'));
has endPoint       => (is => 'rw', trigger => triggerUnit('endPoint'));
has spacing        => (is => 'rw', trigger => triggerUnit('spacing'));
has origin         => (is => 'rw', trigger => triggerUnit('origin'));
has min            => (is => 'rw', trigger => triggerUnit('min'));
has max            => (is => 'rw', trigger => triggerUnit('max'));
has paperDimension => (is => 'rw', trigger => triggerUnit('paperDimension'));

# 'x' or 'y'
has axis => (is => 'rw');

# boolean
has canShiftPoints => (is => 'rw', default => 0);

has startVisibleBoundary => (is => 'rw', trigger => triggerUnit('startVisibleBoundary'));
has endVisibleBoundary   => (is => 'rw', trigger => triggerUnit('endVisibleBoundary'));

use Data::Dumper qw(Dumper);
use Storable qw(dclone);

sub BUILD {
    my $self = shift;

    # if constructor called with, e.g., spacing => '1unit', convert it.
    foreach my $method (qw(startPoint endPoint spacing origin min max)) {
        $self->$method($self->$method) if defined $self->$method;
    }

    if (!defined $self->origin && defined $self->min && defined $self->max) {
        $self->origin(($self->min + $self->max) / 2);
    }

    if (!defined $self->spacing) {
        $self->spacing('1unit');
    }

    # what to base shiftpoints on
    my $min = $self->min;
    my $max = $self->max;

    my $startVisibleBoundary = $self->startVisibleBoundary;
    my $endVisibleBoundary   = $self->endVisibleBoundary;

    if (defined $startVisibleBoundary) {
        if ($min < $startVisibleBoundary) {
            $min = $startVisibleBoundary;
        }
    }
    if (defined $endVisibleBoundary) {
        if ($max > $endVisibleBoundary) {
            $max = $endVisibleBoundary;
        }
    }

    $self->setPoints();

    if ($self->canShiftPoints) {
        my $pointCount  = $self->getPointCount;
        my $pointCount2 = $self->getPointCount($self->spacing / 2);
        if ($pointCount2 > $pointCount) {
            my $beforeOrigin = $self->origin;
            $self->origin($self->origin - $self->spacing / 2);
            $self->startPoint(undef);
            $self->endPoint(undef);
            $self->setPoints();
        }
    }
}

sub getPointCount {
    my ($self, $diff) = @_;
    $diff //= 0;

    my $startPoint = $self->startPoint + $diff;
    my $endPoint   = $self->endPoint   + $diff;
    my $spacing    = $self->spacing;

    my $min = $self->min;
    my $max = $self->max;

    my $startVisibleBoundary = $self->startVisibleBoundary;
    my $endVisibleBoundary   = $self->endVisibleBoundary;

    if (defined $startVisibleBoundary) {
        if ($min < $startVisibleBoundary) {
            $min = $startVisibleBoundary;
        }
    }
    if (defined $endVisibleBoundary) {
        if ($max > $endVisibleBoundary) {
            $max = $endVisibleBoundary;
        }
    }

    while (snapcmp($startPoint, $min) > 0) { $startPoint -= $spacing; }
    while (snapcmp($startPoint, $min) < 0) { $startPoint += $spacing; }

    while (snapcmp($endPoint,   $max) < 0) { $endPoint   += $spacing; }
    while (snapcmp($endPoint,   $max) > 0) { $endPoint   -= $spacing; }

    return round(($endPoint - $startPoint) / $spacing);
}

sub setPoints {
    my ($self) = @_;

    my $min = $self->min;
    my $max = $self->max;

    my $startPoint = $self->startPoint;
    my $endPoint   = $self->endPoint;
    my $origin     = $self->origin;
    my $spacing    = $self->spacing;

    if (defined $min && !defined $startPoint) {
        $startPoint = $origin;
        while (1) {
            my $next = $startPoint - $spacing;
            if (snapcmp($next, $min) < 0) {
                last;
            }
            $startPoint = $next;
        }
        $self->startPoint($startPoint);
    }

    if (defined $max && !defined $endPoint) {
        $endPoint = $origin;
        while (1) {
            my $next = $endPoint + $spacing;
            if (snapcmp($next, $max) > 0) {
                last;
            }
            $endPoint = $next;
        }
        $self->endPoint($endPoint);
    }

    # FIXME: there are other conditions to test as well, based on what
    # is passed to the constructor at object creation time.  None of
    # them are true right now, and above conditions are always true.
}

sub nearest {
    my ($self, $point) = @_;
    my $spacing = $self->spacing;
    return $self->startPoint + round(($point - $self->startPoint) / $spacing) * $spacing;
}

sub includes {
    my ($self, $point) = @_;
    return 0 if snapcmp($point, $self->startPoint) < 0;
    return 0 if snapcmp($point, $self->endPoint) > 0;
    return snapcmp($point, $self->nearest($point)) == 0;
}

sub extendAhead {
    my ($self, $steps) = @_;
    $steps //= 1;
    $self->max($self->max + $self->spacing * $steps);
    $self->endPoint($self->endPoint + $self->spacing * $steps);
}

sub extendBehind {
    my ($self, $steps) = @_;
    $steps //= 1;
    $self->min($self->min - $self->spacing * $steps);
    $self->startPoint($self->startPoint - $self->spacing * $steps);
}

sub chopBehind {
    my ($self, $min) = @_;
    return unless defined $min;
    while (snapcmp($self->min, $min) < 0) {
        $self->min($self->min + $self->spacing);
    }
    while (snapcmp($self->startPoint, $min) < 0) {
        $self->startPoint($self->startPoint + $self->spacing);
    }
}

sub chopAhead {
    my ($self, $max) = @_;
    return unless defined $max;
    while (snapcmp($self->max, $max) > 0) {
        $self->max($self->max - $self->spacing);
    }
    while (snapcmp($self->endPoint, $max) > 0) {
        $self->endPoint($self->endPoint - $self->spacing);
    }
}

sub getPoints {
    my ($self) = @_;
    my @points;
    for (my $point = $self->startPoint;
         snapcmp($point, $self->endPoint) <= 0;
         $point += $self->spacing) {
        push(@points, $point);
    }
    return @points;
}

sub clone {
    my $self = shift;
    return dclone($self);
}

1;
