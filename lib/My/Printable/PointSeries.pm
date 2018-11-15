package My::Printable::PointSeries;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public 'start';
public 'end';
public 'spacing';
public 'origin';
public 'min';
public 'max';

our $FUDGE = 0.0001;

sub init {
    my ($self) = @_;
    if (defined $self->origin && defined $self->spacing) {
        if (defined $self->min && !defined $self->start) {
            my $start = $self->origin;
            while ((my $new_start = $start - $self->spacing) >= ($self->min - $FUDGE)) {
                $start = $new_start;
            }
            $self->start($start);
        }
        if (defined $self->max && !defined $self->end) {
            my $end = $self->origin;
            while ((my $new_end = $end + $self->spacing) <= ($self->max + $FUDGE)) {
                $end = $new_end;
            }
            $self->end($end);
        }
    }
}

sub extendAhead {
    my ($self, $steps) = @_;
    $steps //= 1;
    $self->max($self->max + $self->spacing * $steps);
}

sub extendBehind {
    my ($self, $steps) = @_;
    $steps //= 1;
    $self->min($self->min - $self->spacing * $steps);
}

sub chopBehind {
    my ($self, $min) = @_;
    return unless defined $min;
    while ($self->min < ($min - $FUDGE)) {
        $self->min($self->min + $self->spacing);
    }
}

sub chopAhead {
    my ($self, $max) = @_;
    return unless defined $max;
    while ($self->max > ($max + $FUDGE)) {
        $self->max($self->max - $self->spacing);
    }
}

sub getPoints {
    my ($self) = @_;
    my @points;
    for (my $point = $self->min; $point <= ($self->max + $FUDGE); $point += $self->spacing) {
        push(@points, $point);
    }
    return @points;
}

1;
