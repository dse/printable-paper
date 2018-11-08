package My::Printable::Element::Grid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public "cssClassHorizontal";
public "cssClassVertical";
public "isDotGrid", default => 0;
public "isEnclosed", default => 0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;
    my $x1 = $self->leftMargin;
    my $x2 = $self->rightMargin;
    my $y1 = $self->bottomMargin;
    my $y2 = $self->topMargin;
    if ($self->isDotGrid) {
        foreach my $x (@{$self->xValues}) {
            foreach my $y (@{$self->yValues}) {
                my $cssClass = $self->cssClass // "blue dot";
                my $line = $self->createLine(x => $x, y => $y, cssClass => $cssClass);
                $self->appendLine($line);
            }
        }
    } else {
        if ($self->isEnclosed) {
            $x1 = min(@{$self->xValues});
            $x2 = max(@{$self->xValues});
            $y1 = min(@{$self->yValues});
            $y2 = max(@{$self->yValues});
        }

        # vertical lines
        foreach my $x (@{$self->xValues}) {
            my $cssClass = $self->cssClassVertical // $self->cssClass // "thin blue line";
            my $line = $self->createLine(x => $x, y1 => $y1, y2 => $y2, cssClass => $cssClass);
            $self->appendLine($line);
        }

        # horizontal lines
        foreach my $y (@{$self->yValues}) {
            my $cssClass = $self->cssClassHorizontal // $self->cssClass // "thin blue line";
            my $line = $self->createLine(y => $y, x1 => $x1, x2 => $x2, cssClass => $cssClass);
            $self->appendLine($line);
        }
    }
}

1;
