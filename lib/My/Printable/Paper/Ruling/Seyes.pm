package My::Printable::Paper::Ruling::Seyes;
# French or Séyès ruling.
use utf8;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling::SeyesClass';

use My::Printable::Paper::Element::Grid;
use My::Printable::Paper::Element::Lines;
use My::Printable::Paper::Element::Line;

use POSIX qw(round);

use constant rulingName => 'seyes';
use constant hasLineGrid => 1;
use constant hasLeftMarginLine => 1;

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $dividingLines = $self->modifiers->get('dividing-lines') || $self->modifiers->get('feint-lines');

    if (defined $dividingLines) {
        $dividingLines = round($dividingLines);
        $dividingLines = undef if $dividingLines < 2;
    }

    my $grid = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getFeintLineCSSClass,
    );
    $grid->setX1($self->getOriginX);
    $grid->setY1($self->getTopLineY);
    $grid->setY2($self->getBottomLineY);
    $grid->setSpacingX('1unit');
    if (defined $dividingLines) {
        my $spacingY = sprintf('1/%g unit', $dividingLines);
        $grid->setSpacingY($spacingY);
    } elsif ($self->modifiers->has('three-line')) {
        $grid->setSpacingY('1/3unit');
    } else {
        $grid->setSpacingY('1/4unit');
    }
    $grid->extendVerticalGridLines(1);
    $grid->extendHorizontalGridLines(1);
    if (defined $dividingLines) {
        if ($dividingLines > 1) {
            $grid->extendTop($dividingLines - 1);
        }
        if ($dividingLines > 2) {
            $grid->extendBottom($dividingLines - 2);
        }
    } elsif ($self->modifiers->has('three-line')) {
        $grid->extendTop(2);
        $grid->extendBottom(1);
    } else {
        $grid->extendTop(3);
        $grid->extendBottom(2);
    }

    my $lines = My::Printable::Paper::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        cssClass => $self->getRegularLineCSSClass,
    );
    $lines->setY1($self->getTopLineY);
    $lines->setY2($self->getBottomLineY);
    $lines->setSpacing('1unit');

    $self->document->appendElement($grid);
    $self->document->appendElement($lines);

    $self->$orig();
};

1;
