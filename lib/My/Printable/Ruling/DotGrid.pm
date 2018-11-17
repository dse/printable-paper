package My::Printable::Ruling::DotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling::Quadrille';

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'dot-grid';

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
    $self->document->generate;
}

sub getDotCSSClass {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return 'gray dot';
    } else {
        return 'blue dot';
    }
}

1;
