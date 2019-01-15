package My::Printable::Ruling::DotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Ruling';

use My::Printable::Element::Grid;

use constant rulingName => 'dot-grid';
use constant hasLineGrid => 0;

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getDotCSSClass,
    );
    $grid->isDotGrid(1);
    $grid->setSpacing('1unit');

    $self->document->appendElement($grid);

    $self->$orig();
};

1;
