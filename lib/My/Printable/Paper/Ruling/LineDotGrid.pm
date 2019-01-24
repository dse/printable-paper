package My::Printable::Paper::Ruling::LineDotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling';

use My::Printable::Paper::Element::Grid;
use My::Printable::Paper::Element::Lines;
use My::Printable::Paper::Unit qw(:const);

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

    my $grid = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getDotCSSClass,
    );
    $grid->isDotGrid(1);
    $grid->setSpacing('1unit');

    my $lines = My::Printable::Paper::Element::Lines->new(
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
