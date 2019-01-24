package My::Printable::Paper::Ruling::LineDotGraph;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling::SeyesClass';

use My::Printable::Paper::Element::Grid;
use My::Printable::Paper::Element::Line;
use My::Printable::Paper::Unit qw(:const);

use constant rulingName => 'line-dot-graph';
use constant hasLineGrid => 0;
use constant hasMarginLine => 1;

sub baseDotWidth {
    my ($self) = @_;
    return 4 * sqrt(2) * PD if $self->colorType eq 'black';
    return 8 * sqrt(2) * PD;
}

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $grid = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClassHorizontal => $self->getLineCSSClass,
        cssClassVertical => $self->getDotCSSClass,
    );
    $grid->setX1($self->getOriginX);
    $grid->setY1($self->getTopLineY);
    $grid->setY2($self->getBottomLineY);
    $grid->setSpacing('1unit');
    if ($self->modifiers->has('three-line')) {
        $grid->verticalDots(3);
    } else {
        $grid->verticalDots(4);
    }
    $grid->hasDottedVerticalGridLines(1);
    $grid->extendVerticalGridLines(1);
    $grid->extendHorizontalGridLines(1);

    $self->document->appendElement($grid);

    $self->$orig();
};

1;
