package My::Printable::Paper::Ruling::DotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling';

use My::Printable::Paper::Element::Grid;

use constant rulingName => 'dot-grid';
use constant hasLineGrid => 0;

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $grid = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getRegularDotCSSClass,
    );
    $grid->isDotGrid(1);
    $grid->setSpacing('1unit');

    $self->document->appendElement($grid);

    $self->$orig();
};

1;
