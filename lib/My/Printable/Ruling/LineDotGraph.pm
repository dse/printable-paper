package My::Printable::Ruling::LineDotGraph;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling::Seyes';

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'line-dot-graph';
use constant hasLineGrid => 0;
use constant dotThinness => 2;

sub generate {
    my ($self) = @_;

    $self->document->setUnit($self->getUnit);
    $self->document->setOriginX($self->getOriginX);
    $self->document->setOriginY($self->getOriginY);

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClassHorizontal => $self->getLineCSSClass,
        cssClassVertical => $self->getDotCSSClass,
    );
    $grid->setX1($self->getOriginX);
    $grid->setY1($self->getTopLineY);
    $grid->setY2($self->getBottomLineY);
    $grid->setSpacing('1unit');
    if ($self->hasModifier->{'three-line'}) {
        $grid->verticalDots(3);
    } else {
        $grid->verticalDots(4);
    }
    $grid->hasDottedVerticalGridLines(1);
    $grid->extendVerticalGridLines(1);
    $grid->extendHorizontalGridLines(1);

    my $margin_line = My::Printable::Element::Line->new(
        document => $self->document,
        id => 'margin-line',
        cssClass => $self->getMarginLineCSSClass,
    );
    $margin_line->setX($self->getOriginX);

    $self->document->appendElement($grid);
    $self->document->appendElement($margin_line);
    $self->document->generate;
}

1;
