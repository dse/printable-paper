package My::Printable::Ruling::LineDotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling::Quadrille';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'line-dot-grid';
use constant hasLineGrid => 0;
use constant lineThinness => 1;
use constant dotThinness => -1;

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

    my $lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        cssClass => $self->getLineCSSClass,
    );
    $lines->setSpacing('1unit');

    $self->document->appendElement($grid);
    $self->document->appendElement($lines);
    $self->document->generate;
}

1;
