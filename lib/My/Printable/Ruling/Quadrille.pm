package My::Printable::Ruling::Quadrille;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling';

use constant rulingName => 'quadrille';

sub generate {
    my ($self) = @_;
    $self->document->setUnit($self->getUnit);

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getLineCSSClass,
    );
    $grid->setSpacing('1unit');

    $self->document->appendElement($grid);
    $self->document->generate;
}

sub getLineCSSClass {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return 'x-thin gray line';
    } else {
        return 'x-thin blue line';
    }
}

1;
