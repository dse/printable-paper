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
    my $x1 = $self->x1;
    my $x2 = $self->x2;
    my $y1 = $self->y1;
    my $y2 = $self->y2;
    my $cssClass = $self->cssClass // "blue line";
    my $line = $self->createLine(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, cssClass => $cssClass);
    $self->appendLine($line);
}

1;
