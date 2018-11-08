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
        my $x1 = $self->leftMargin;
        my $x2 = $self->rightMargin;
        foreach my $y (@{$self->yValues}) {
            my $line = $self->createLine(y => $y, x1 => $x1, x2 => $x2, cssClass => $cssClass);
            $self->appendLine($line);
        }
    } elsif ($self->direction eq "vertical") {
        my $y1 = $self->bottomMargin;
        my $y2 = $self->topMargin;
        foreach my $x (@{$self->xValues}) {
            my $line = $self->createLine(x => $x, y1 => $y1, y2 => $y2, cssClass => $cssClass);
            $self->appendLine($line);
        }
    }
}

1;
