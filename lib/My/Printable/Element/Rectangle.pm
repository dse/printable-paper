package My::Printable::Element::Rectangle;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public 'rx';
public 'ry';
public 'r';

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;
    my $x1 = $self->x1 // $self->document->leftMarginX;
    my $x2 = $self->x2 // $self->document->rightMarginX;
    my $y1 = $self->y1 // $self->document->topMarginY;
    my $y2 = $self->y2 // $self->document->bottomMarginY;
    my $rx = $self->rx // $self->r;
    my $ry = $self->ry // $self->r;
    my $cssClass = $self->cssClass // "blue line";
    my $rectangle = $self->createSVGRectangle(
        x => $x1, y => $y1, width => $x2 - $x1, height => $y2 - $y1,
        rx => $self->rx, ry => $self->ry,
        cssClass => $cssClass
    );
    $self->appendSVGElement($rectangle);
}

1;
