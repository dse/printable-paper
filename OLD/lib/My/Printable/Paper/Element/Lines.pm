package My::Printable::Paper::Element::Lines;
use warnings;
use strict;
use v5.10.0;

use Moo;

# 'horizontal' or 'vertical'
has direction => (
    is => 'rw',
    default => 'horizontal',
);

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::PointSeries;
use My::Printable::Paper::Util qw(strokeDashArray strokeDashOffset :trigger);

use Moo;

extends qw(My::Printable::Paper::Element);

has isDotted    => (is => 'rw', default => 0);
has dotCenter   => (is => 'rw', default => 0, trigger => triggerWrapper(\&triggerDotCenter));
has dotSpacing  => (is => 'rw', default => 18, trigger => triggerWrapper(\&triggerDotSpacing));

has isDashed    => (is => 'rw', default => 0);
has dashCenter  => (is => 'rw', default => 0, trigger => triggerWrapper(\&triggerDashCenter));
has dashSize    => (is => 'rw', default => 0.5);
has dashSpacing => (is => 'rw', default => 18, trigger => triggerWrapper(\&triggerDashSpacing));

sub triggerDotCenter {
    my ($self, $value) = @_;
    return $self->dotCenter($self->ptX($value)) if $self->direction eq 'horizontal';
    return $self->dotCenter($self->ptY($value)) if $self->direction eq 'vertical';
    return $self->dotCenter($self->pt($value));
}

sub triggerDotSpacing {
    my ($self, $value) = @_;
    return $self->dotSpacing($self->ptX($value)) if $self->direction eq 'horizontal';
    return $self->dotSpacing($self->ptY($value)) if $self->direction eq 'vertical';
    return $self->dotSpacing($self->pt($value));
}

sub triggerDashCenter {
    my ($self, $value) = @_;
    return $self->dashCenter($self->ptX($value)) if $self->direction eq 'horizontal';
    return $self->dashCenter($self->ptY($value)) if $self->direction eq 'vertical';
    return $self->dashCenter($self->pt($value));
}

sub triggerDashSpacing {
    my ($self, $value) = @_;
    return $self->dashSpacing($self->ptX($value)) if $self->direction eq 'horizontal';
    return $self->dashSpacing($self->ptY($value)) if $self->direction eq 'vertical';
    return $self->dashSpacing($self->pt($value));
}

sub draw {
    my ($self) = @_;
    my $cssClass = $self->cssClass // "thin blue line";
    if ($self->isDotted) {
        $cssClass =~ s{(^|\s)line($|\s)}
                      {$1dot$2}g;
        $cssClass =~ s{(^|\s)major-line($|\s)}
                      {$1major-dot$2}g;
        $cssClass =~ s{(^|\s)regular-line($|\s)}
                      {$1regular-dot$2}g;
        $cssClass =~ s{(^|\s)feint-line($|\s)}
                      {$1feint-dot$2}g;
    }
    if ($self->direction eq "horizontal") {
        my $x1 = $self->x1 // $self->document->leftMarginX;
        my $x2 = $self->x2 // $self->document->rightMarginX;
        my $strokeDashArray;
        my $strokeDashOffset;
        if ($self->isDashed) {
            my %args = (
                min => $x1,
                max => $x2,
                length => $self->dashSize * $self->dashSpacing,
                spacing => $self->dashSpacing,
                center => $x1,
            );
            $strokeDashArray = strokeDashArray(%args);
            $strokeDashOffset = strokeDashOffset(%args);
        } elsif ($self->isDotted) {
            my %args = (
                min => $x1,
                max => $x2,
                length => 0,
                spacing => $self->dotSpacing,
                center => $x1,
            );
            $strokeDashArray = strokeDashArray(%args);
            $strokeDashOffset = strokeDashOffset(%args);
        }
        foreach my $y ($self->yPointSeries->getPoints) {
            next if $self->excludesY($y);
            my %line = (
                y => $y, x1 => $x1, x2 => $x2,
                cssClass => $cssClass,
            );
            my $line = $self->createSVGLine(%line);
            if ($self->isDashed || $self->isDotted) {
                $line{attr} = {
                    'stroke-dasharray' => $strokeDashArray,
                    'stroke-dashoffset' => $strokeDashOffset,
                };
            }
            $self->appendSVGElement($line);
        }
    } elsif ($self->direction eq "vertical") {
        my $y1 = $self->y1 // $self->document->topMarginY;
        my $y2 = $self->y2 // $self->document->bottomMarginY;
        my $strokeDashArray;
        my $strokeDashOffset;
        if ($self->isDashed) {
            my %args = (
                min => $y1,
                max => $y2,
                length => $self->dashSize * $self->dashSpacing,
                spacing => $self->dashSpacing,
                center => $y1,
            );
            $strokeDashArray = strokeDashArray(%args);
            $strokeDashOffset = strokeDashOffset(%args);
        } elsif ($self->isDotted) {
            my %args = (
                min => $y1,
                max => $y2,
                length => 0,
                spacing => $self->dotSpacing,
                center => $y1,
            );
            $strokeDashArray = strokeDashArray(%args);
            $strokeDashOffset = strokeDashOffset(%args);
        }
        foreach my $x ($self->xPointSeries->getPoints) {
            next if $self->excludesX($x);
            my %line = (
                x => $x, y1 => $y1, y2 => $y2,
                cssClass => $cssClass,
            );
            if ($self->isDashed || $self->isDotted) {
                $line{attr} = {
                    'stroke-dasharray' => $strokeDashArray,
                    'stroke-dashoffset' => $strokeDashOffset,
                };
            }
            my $line = $self->createSVGLine(%line);
            $self->appendSVGElement($line);
        }
    }
}

1;
