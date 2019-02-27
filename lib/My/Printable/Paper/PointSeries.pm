package My::Printable::Paper::PointSeries;
use warnings;
use strict;
use v5.10.0;

use POSIX qw(trunc round);

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:around :const snapcmp snapnum);

use Moo;

has 'startPoint'     => (is => 'rw');
has 'endPoint'       => (is => 'rw');
has 'spacing'        => (is => 'rw');
has 'origin'         => (is => 'rw');
has 'min'            => (is => 'rw');
has 'max'            => (is => 'rw');
has 'edgeMargin'     => (is => 'rw', default => 18); # 0.25in
has 'paperDimension' => (is => 'rw'); # width or height of document

# 'x' or 'y'
has 'axis' => (is => 'rw');

# boolean
has 'shiftPoints' => (is => 'rw', default => 0);

around 'startPoint'     => \&aroundUnit;
around 'endPoint'       => \&aroundUnit;
around 'spacing'        => \&aroundUnit;
around 'origin'         => \&aroundUnit;
around 'min'            => \&aroundUnit;
around 'max'            => \&aroundUnit;
around 'edgeMargin'     => \&aroundUnit;
around 'paperDimension' => \&aroundUnit;

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
    if (defined $self->edgeMargin && defined $self->paperDimension) {
        my $leftEdge  = $self->edgeMargin;
        my $rightEdge = $self->paperDimension - $self->edgeMargin;
        if ($min < $leftEdge) {
            $min = $leftEdge;
        }
        if ($max > $rightEdge) {
            $max = $rightEdge;
        }
    }

    $self->setPoints();

    if ($self->shiftPoints) {
        my $pointCount  = $self->getPointCount;
        my $pointCount2 = $self->getPointCount($self->spacing / 2);
        if ($pointCount2 > $pointCount) {
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
    my $edgeMargin = $self->edgeMargin;
    my $paperDimension = $self->paperDimension;
    if (defined $edgeMargin && defined $paperDimension) {
        my $startEdge = $edgeMargin;
        my $endEdge   = $paperDimension - $edgeMargin;
        if ($min < $startEdge) { $min = $startEdge; }
        if ($max > $endEdge)   { $max = $endEdge;   }
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
