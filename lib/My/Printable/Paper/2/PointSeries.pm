package My::Printable::Paper::2::PointSeries;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Util qw(:snap);

use POSIX qw(round);
use List::Util qw(min max);

use Moo;

has id                       => (is => 'rw');
has axis                     => (is => 'rw');
has from                     => (is => 'rw', default => '0pt from start');
has to                       => (is => 'rw', default => '0pt from end');
has origin                   => (is => 'rw', default => '50%');
has step                     => (is => 'rw', default => '1 grid');
has center                   => (is => 'rw', default => 0);
has canShiftPoints           => (is => 'rw', default => 0);
has extend                   => (is => 'rw', default => 0);
has paper                    => (is => 'rw');
has computedOrigin           => (is => 'rw');
has computedPoints           => (is => 'rw');
has centerUsingClipPath      => (is => 'rw', default => 1);
has shiftPointsUsingClipPath => (is => 'rw', default => 1);
has canExclude               => (is => 'rw');
has mustExclude              => (is => 'rw');
has actualStart              => (is => 'rw');
has actualEnd                => (is => 'rw');
has actualStep               => (is => 'rw');

sub compute {
    my $self = shift;
    my $size;
    if (!defined $self->axis) {
        die("getPoints: axis must be defined");
    } elsif ($self->axis eq 'x') {
        $size = $self->paper->xx('width');
    } elsif ($self->axis eq 'y') {
        $size = $self->paper->yy('height');
    } else {
        die("getPoints: axis must be 'x' or 'y'");
    }
    my $fromPt = $self->paper->coordinate($self->from, $self->axis);
    my $toPt   = $self->paper->coordinate($self->to, $self->axis);
    my $step   = $self->paper->coordinate($self->step, $self->axis);
    my $origin = $self->paper->coordinate($self->origin // $self->from,
                                          $self->axis);
    my @pts = ($origin);
    my $pt;
    for ($pt = $origin + $step; snapcmp($pt, $toPt) < 0; $pt += $step) {
        push(@pts, $pt);
    }
    for ($pt = $origin - $step; snapcmp($pt, $fromPt) > 0; $pt -= $step) {
        unshift(@pts, $pt);
    }
    if ($self->center) {
        my $fromStart = $pts[0];
        my $fromEnd   = $size - $pts[scalar(@pts) - 1];
        if ($self->centerUsingClipPath) {
            if ($self->axis eq 'x') {
                $fromStart -= eval { $self->paper->xx('clipLeft')  } // 0;
                $fromEnd   -= eval { $self->paper->xx('clipRight') } // 0;
            } elsif ($self->axis eq 'y') {
                $fromStart -= eval { $self->paper->xx('clipTop')    } // 0;
                $fromEnd   -= eval { $self->paper->xx('clipBottom') } // 0;
            }
        }
        my $average   = ($fromStart + $fromEnd) / 2;
        my $shift     = $average - $fromStart;

        @pts = map { $_ + $shift } @pts;
        $origin += $shift;
    }
    if ($self->canShiftPoints) {
        my $fromStart = $pts[0];
        my $fromEnd   = $size - $pts[scalar(@pts) - 1];
        if ($self->shiftPointsUsingClipPath) {
            if ($self->axis eq 'x') {
                $fromStart -= eval { $self->paper->xx('clipLeft')  } // 0;
                $fromEnd   -= eval { $self->paper->xx('clipRight') } // 0;
            } elsif ($self->axis eq 'y') {
                $fromStart -= eval { $self->paper->xx('clipTop')    } // 0;
                $fromEnd   -= eval { $self->paper->xx('clipBottom') } // 0;
            }
            while (snapcmp($fromStart, 0) < 0) {
                $fromStart += $step;
            }
            while (snapcmp($fromEnd, 0) < 0) {
                $fromEnd += $step;
            }
        }
        if (snapcmp($fromStart, $step / 2) >= 0 &&
                snapcmp($fromEnd, $step / 2) >= 0) {
            @pts = map { $_ - $step / 2 } @pts;
            push(@pts, $pts[scalar(@pts) - 1] + $step);
            $origin -= $step / 2;
        }
    }
    if ($self->extend) {
        for ($pt = $pts[scalar(@pts) - 1] + $step;
             snapcmp($pt, $size) <= 0;
             $pt += $step) {
            push(@pts, $pt);
        }
        for ($pt = $pts[0] - $step; snapcmp($pt, 0) >= 0; $pt -= $step) {
            unshift(@pts, $pt);
        }
    }
    $self->actualStart(min(@pts));
    $self->actualEnd(max(@pts));
    $self->actualStep($step);
    $self->computedOrigin($origin);
    $self->computedPoints(\@pts);
}

sub getPoints {
    my $self = shift;
    $self->compute();
    my @points = @{$self->computedPoints};
    if ($self->canExclude) {
        @points = grep { !$self->canExclude->includes($_) } @points;
    }
    if ($self->mustExclude) {
        @points = grep { !$self->mustExclude->includes($_) } @points;
    }
    return @points;
}

sub getOrigin {
    my $self = shift;
    $self->compute();
    return $self->computedOrigin;
}

sub nearest {
    my $self = shift;
    my $value = shift;
    $value = $self->paper->coordinate($value, $self->axis);
    my $start = $self->actualStart;
    my $step = $self->actualStep;
    my $end = $self->actualEnd;
    my $nearest = $start + round(($value - $start) / $step) * $step;
    if (snapcmp($nearest, $start) < 0) {
        return $start;
    }
    if (snapcmp($nearest, $end) > 0) {
        return $end;
    }
    return $nearest;
}

sub includes {
    my $self = shift;
    my $value = shift;
    $value = $self->paper->coordinate($value, $self->axis);
    my $start = $self->actualStart;
    my $step = $self->actualStep;
    my $end = $self->actualEnd;
    my $nearest = $start + round(($value - $start) / $step) * $step;
    if (snapcmp($nearest, $start) < 0) {
        return 0;
    }
    if (snapcmp($nearest, $end) > 0) {
        return 0;
    }
    return snapcmp($nearest, $value) == 0;
}

1;
