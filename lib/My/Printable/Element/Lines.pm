package My::Printable::Element::Lines;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public "direction", default => "horizontal"; # or 'vertical'

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;
    my $cssClass = $self->cssClass // "thin blue line";
    if ($self->direction eq "horizontal") {
        my $x1 = $self->leftMarginX;
        my $x2 = $self->rightMarginX;
        foreach my $y (@{$self->yValues}) {
            my $line = $self->createSVGLine(y => $y, x1 => $x1, x2 => $x2, cssClass => $cssClass);
            $self->appendSVGLine($line);
        }
    } elsif ($self->direction eq "vertical") {
        my $y1 = $self->bottomMarginY;
        my $y2 = $self->topMarginY;
        foreach my $x (@{$self->xValues}) {
            my $line = $self->createSVGLine(x => $x, y1 => $y1, y2 => $y2, cssClass => $cssClass);
            $self->appendSVGLine($line);
        }
    }
}

1;
