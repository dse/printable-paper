package My::Printable::PointSeries;
use warnings;
use strict;
use v5.10.0;

use Moo;

has 'startPoint' => (is => 'rw');
has 'endPoint' => (is => 'rw');
has 'spacing' => (is => 'rw');
has 'origin' => (is => 'rw');
has 'min' => (is => 'rw');
has 'max' => (is => 'rw');

our $FUDGE = 0.0001;

sub BUILD {
    my $self = shift;
    if (defined $self->origin && defined $self->spacing) {
        if (defined $self->min && !defined $self->startPoint) {
            my $start = $self->origin;
            while ((my $new_start = $start - $self->spacing) >= ($self->min - $FUDGE)) {
                $start = $new_start;
            }
            $self->startPoint($start);
        }
        if (defined $self->max && !defined $self->endPoint) {
            my $end = $self->origin;
            while ((my $new_end = $end + $self->spacing) <= ($self->max + $FUDGE)) {
                $end = $new_end;
            }
            $self->endPoint($end);
        }
    }
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
    while ($self->min < ($min - $FUDGE)) {
        $self->min($self->min + $self->spacing);
    }
    while ($self->startPoint < ($min - $FUDGE)) {
        $self->startPoint($self->startPoint + $self->spacing);
    }
}

sub chopAhead {
    my ($self, $max) = @_;
    return unless defined $max;
    while ($self->max > ($max + $FUDGE)) {
        $self->max($self->max - $self->spacing);
    }
    while ($self->endPoint > ($max + $FUDGE)) {
        $self->endPoint($self->endPoint - $self->spacing);
    }
}

sub getPoints {
    my ($self) = @_;
    my @points;
    for (my $point = $self->startPoint; $point <= ($self->endPoint + $FUDGE); $point += $self->spacing) {
        push(@points, $point);
    }
    return @points;
}

1;
