package My::Printable::Ruling::DotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling::Quadrille';

use My::Printable::Element::Grid;

use constant rulingName => 'dot-grid';
use constant hasLineGrid => 0;

sub generate {
    my ($self) = @_;
    $self->document->setUnit($self->getUnit);

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getDotCSSClass,
    );
    $grid->isDotGrid(1);
    $grid->setSpacing('1unit');

    $self->document->appendElement($grid);

    $self->My::Printable::Ruling::generate();
}

1;
