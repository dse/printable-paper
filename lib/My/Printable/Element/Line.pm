package My::Printable::Element::Line;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;
    my $x1 = $self->x1 // $self->document->leftMarginX;
    my $x2 = $self->x2 // $self->document->rightMarginX;
    my $y1 = $self->y1 // $self->document->topMarginY;
    my $y2 = $self->y2 // $self->document->bottomMarginY;
    my $cssClass = $self->cssClass // "blue line";
    my $line = $self->createSVGLine(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, cssClass => $cssClass);
    $self->appendSVGLine($line);
}

1;
