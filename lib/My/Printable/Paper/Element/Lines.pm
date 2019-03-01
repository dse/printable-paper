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

use Moo;

extends qw(My::Printable::Paper::Element);

has isDotted    => (is => 'rw', default => 0);
has dotCenter   => (is => 'rw', default => 0);
has dotSpacing  => (is => 'rw', default => 0);

has isDashed    => (is => 'rw', default => 0);
has dashCenter  => (is => 'rw', default => 0);
has dashLength  => (is => 'rw', default => 0);
has dashSpacing => (is => 'rw', default => 0);

sub draw {
    my ($self) = @_;
    my $cssClass = $self->cssClass // "thin blue line";
    if ($self->direction eq "horizontal") {
        my $x1 = $self->x1 // $self->document->leftMarginX;
        my $x2 = $self->x2 // $self->document->rightMarginX;
        my $strokeDashArray;
        my $strokeDashOffset;
        if ($self->isDashed) {
            my %args = (
                min => $x1,
                max => $x2,
                length => $self->dashLength,
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
                length => $self->dashLength,
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
