package My::Printable::Paper::PointSeries;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:around :const);

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

sub BUILD {
    my $self = shift;

    # if constructor called with, e.g., spacing => '1unit', convert it.
    foreach my $method (qw(startPoint endPoint spacing origin min max)) {
        $self->$method($self->$method) if defined $self->$method;
    }

    if (!defined $self->origin) {
        $self->origin(($self->min + $self->max) / 2);
    }

    if (!defined $self->spacing) {
        $self->spacing('1unit');
    }

    # what to base shiftpoints on
    my $min = $self->min;
    my $max = $self->max;
    if (defined $self->edgeMargin && defined $self->paperDimension) {
        $min = $self->edgeMargin;
        $max = $self->paperDimension - $self->edgeMargin;
    }

    $self->setPoints();

    if ($self->shiftPoints) {
        my $leftSpace = $self->startPoint - $min;
        my $rightSpace = $max - $self->endPoint;
        my $leftSpaceHalf = $leftSpace - $self->spacing / 2;
        my $rightSpaceHalf = $rightSpace - $self->spacing / 2;
        if ($leftSpaceHalf >= -FUDGE_FACTOR && $rightSpaceHalf >= -FUDGE_FACTOR) {
            $self->origin($self->origin - $self->spacing / 2);
            $self->startPoint(undef);
            $self->endPoint(undef);
            $self->setPoints();
        }
    }
}

sub setPoints {
    my ($self) = @_;

    if (defined $self->min && !defined $self->startPoint) {
        my $start = $self->origin;
        while ((my $new_start = $start - $self->spacing) >= ($self->min - FUDGE_FACTOR)) {
            $start = $new_start;
        }
        $self->startPoint($start);
    }

    if (defined $self->max && !defined $self->endPoint) {
        my $end = $self->origin;
        while ((my $new_end = $end + $self->spacing) <= ($self->max + FUDGE_FACTOR)) {
            $end = $new_end;
        }
        $self->endPoint($end);
    }

    # FIXME: there are other conditions to test as well.  None of them
    # are true right now, and above conditions are always true.
}

use POSIX qw(trunc);

sub nearest {
    my ($self, $point) = @_;
    my $x = $point - $self->startPoint;
    my $y = $self->spacing;
    my $t = trunc($x / $y) * $y;
    my $m = $x - $t;
    if ($m < $y / 2) {
        return $self->startPoint + $t;
    } else {
        return $self->startPoint + $y + $t;
    }
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
    while ($self->min < ($min - FUDGE_FACTOR)) {
        $self->min($self->min + $self->spacing);
    }
    while ($self->startPoint < ($min - FUDGE_FACTOR)) {
        $self->startPoint($self->startPoint + $self->spacing);
    }
}

sub chopAhead {
    my ($self, $max) = @_;
    return unless defined $max;
    while ($self->max > ($max + FUDGE_FACTOR)) {
        $self->max($self->max - $self->spacing);
    }
    while ($self->endPoint > ($max + FUDGE_FACTOR)) {
        $self->endPoint($self->endPoint - $self->spacing);
    }
}

sub getPoints {
    my ($self) = @_;
    my @points;
    for (my $point = $self->startPoint; $point <= ($self->endPoint + FUDGE_FACTOR); $point += $self->spacing) {
        push(@points, $point);
    }
    return @points;
}

1;
