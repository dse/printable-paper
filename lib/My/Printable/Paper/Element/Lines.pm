package My::Printable::Paper::Element::Lines;
use warnings;
use strict;
use v5.10.0;

use Moo;

# 'horizontal' or 'vertical'
has 'direction' => (
    is => 'rw',
    default => 'horizontal',
);

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::PointSeries;

use Moo;

extends qw(My::Printable::Paper::Element);

sub draw {
    my ($self) = @_;
    my $cssClass = $self->cssClass // "thin blue line";
    if ($self->direction eq "horizontal") {
        my $x1 = $self->x1 // $self->document->leftMarginX;
        my $x2 = $self->x2 // $self->document->rightMarginX;
        foreach my $y ($self->yPointSeries->getPoints) {
            my $line = $self->createSVGLine(
                y => $y, x1 => $x1, x2 => $x2,
                cssClass => $cssClass,
            );
            $self->appendSVGElement($line);
        }
    } elsif ($self->direction eq "vertical") {
        my $y1 = $self->y1 // $self->document->topMarginY;
        my $y2 = $self->y2 // $self->document->bottomMarginY;
        foreach my $x ($self->xPointSeries->getPoints) {
            my $line = $self->createSVGLine(
                x => $x, y1 => $y1, y2 => $y2,
                cssClass => $cssClass,
            );
            $self->appendSVGElement($line);
        }
    }
}

1;
