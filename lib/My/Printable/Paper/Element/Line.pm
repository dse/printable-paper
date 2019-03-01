package My::Printable::Paper::Element::Line;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use My::Printable::Paper::Util qw(strokeDashArray strokeDashOffset);

use Moo;

extends qw(My::Printable::Paper::Element);

has isDotted   => (is => 'rw', default => 0);
has dotCenter  => (is => 'rw', default => 0);
has dotSpacing => (is => 'rw', default => 0);

has isDashed    => (is => 'rw', default => 0);
has dashCenter  => (is => 'rw', default => 0);
has dashLength  => (is => 'rw', default => 0);
has dashSpacing => (is => 'rw', default => 0);

# stroke-dasharray
# stroke-dashoffset

sub draw {
    my ($self) = @_;
    my $x1 = $self->x1 // $self->document->leftMarginX;
    my $x2 = $self->x2 // $self->document->rightMarginX;
    my $y1 = $self->y1 // $self->document->topMarginY;
    my $y2 = $self->y2 // $self->document->bottomMarginY;
    my $cssClass = $self->cssClass // "blue line";

    my $strokeDashArray;
    my $strokeDashOffset;

    my $dist = sqrt(($x2 - $x1) ** 2 + ($y2 - $y1) ** 2);
    if ($self->isDashed) {
        my %args = (
            min => 0,
            max => $dist,
            length => $self->dashLength,
            spacing => $self->dashSpacing,
            center => $self->dashCenter,
        );
        $strokeDashArray = strokeDashArray(%args);
        $strokeDashOffset = strokeDashOffset(%args);
    } elsif ($self->isDotted) {
        my %args = (
            min => 0,
            max => $dist,
            length => 0,
            spacing => $self->dotSpacing,
            center => $self->dotCenter,
        );
        $strokeDashArray = strokeDashArray(%args);
        $strokeDashOffset = strokeDashOffset(%args);
    }

    my %line = (
        x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2,
        cssClass => $cssClass,
    );
    if ($self->isDashed || $self->isDotted) {
        $line{attr} = {
            'stroke-dasharray' => $strokeDashArray,
            'stroke-dashoffset' => $strokeDashOffset,
        };
    }

    my $line = $self->createSVGLine(%line);
    $self->svgLayer->appendChild($line);
}

sub setWidth {
    my ($self, $value) = @_;
    my $pt = $self->ptX($value);
    if (defined $self->x2 && !defined $self->x1) {
        $self->x1($self->x2 - $pt);
    } elsif (defined $self->x1 && !defined $self->x2) {
        $self->x2($self->x1 + $pt);
    }
}

sub setHeight {
    my ($self, $value) = @_;
    my $pt = $self->ptY($value);
    if (defined $self->y2 && !defined $self->y1) {
        $self->y1($self->y2 - $pt);
    } elsif (defined $self->y1 && !defined $self->y2) {
        $self->y2($self->y1 + $pt);
    }
}

1;
