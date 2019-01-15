package My::Printable::Ruling::LineDotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Ruling';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;
use My::Printable::Unit qw(:const);

use constant rulingName => 'line-dot-grid';
use constant hasLineGrid => 0;

sub baseLineWidth {
    my ($self) = @_;
    return 1 * PD if $self->colorType eq 'black';
    return 4 * PD;
}

sub baseDotWidth {
    my ($self) = @_;
    return 8 * sqrt(2) * PD if $self->colorType eq 'black';
    return 16 * sqrt(2) * PD;
}

around generateRuling => sub {
    my ($orig, $self) = @_;

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

    $self->$orig();
};

1;
