package My::Printable::Element::Line;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;
    my $x1 = $self->x1 // $self->document->leftMarginX;
    my $x2 = $self->x2 // $self->document->rightMarginX;
    my $y1 = $self->y1 // $self->document->topMarginY;
    my $y2 = $self->y2 // $self->document->bottomMarginY;
    my $cssClass = $self->cssClass // "blue line";
    my $line = $self->createSVGLine(
        x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2,
        cssClass => $cssClass,
    );
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
