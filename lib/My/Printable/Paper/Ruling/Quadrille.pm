package My::Printable::Paper::Ruling::Quadrille;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling';

use My::Printable::Paper::Element::Grid;

use POSIX qw(round);
use Data::Dumper;

use constant rulingName => 'quadrille';
use constant hasLineGrid => 1;

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $majorGrid;
    my $grid;
    my $feintGrid;

    my $majorLinesX = $self->modifiers->get('major-lines-x') // $self->modifiers->get('major-lines');
    my $majorLinesY = $self->modifiers->get('major-lines-y') // $self->modifiers->get('major-lines');
    my $feintLines  = $self->modifiers->get('feint-lines');

    my $dashedX      = $self->modifiers->get('dashed')       // $self->modifiers->get('dashed-x');
    my $dashedY      = $self->modifiers->get('dashed')       // $self->modifiers->get('dashed-y');
    my $feintDashedX = $self->modifiers->get('feint-dashed') // $self->modifiers->get('feint-dashed-x');
    my $feintDashedY = $self->modifiers->get('feint-dashed') // $self->modifiers->get('feint-dashed-y');

    foreach my $dashed ($dashedX, $dashedY, $feintDashedX, $feintDashedY) {
        if (defined $dashed && $dashed && $dashed eq 'yes') {
            $dashed = 1;
        }
    }

    if (defined $majorLinesX) {
        $majorLinesX = round($majorLinesX);
        $majorLinesX = undef if $majorLinesX < 2;
    }
    if (defined $majorLinesY) {
        $majorLinesY = round($majorLinesY);
        $majorLinesY = undef if $majorLinesY < 2;
    }

    if (defined $feintLines) {
        $feintLines = round($feintLines);
        $feintLines = undef if $feintLines < 2;
    }

    if (defined $majorLinesX && defined $majorLinesY) {
        $majorGrid = My::Printable::Paper::Element::Grid->new(
            document    => $self->document,
            id          => 'major-grid',
            cssClass    => $self->getMajorLineCSSClass,
            shiftPoints => 1,
        );
        $majorGrid->setSpacingX($majorLinesX . 'unit');
        $majorGrid->setSpacingY($majorLinesY . 'unit');

        $grid = My::Printable::Paper::Element::Grid->new(
            document    => $self->document,
            id          => 'grid',
            cssClass    => $self->getLineCSSClass,
            originX     => $majorGrid->originX,
            originY     => $majorGrid->originY,
            isDashedX   => $dashedX,
            isDashedY   => $dashedY,
            dashesX     => $dashedX,
            dashesY     => $dashedY,
        );
        $grid->setSpacing('1unit');
    } else {
        $grid = My::Printable::Paper::Element::Grid->new(
            document    => $self->document,
            id          => 'grid',
            cssClass    => $self->getLineCSSClass,
            shiftPoints => 1,
            isDashedX   => $dashedX,
            isDashedY   => $dashedY,
            dashesX     => $dashedX,
            dashesY     => $dashedY,
        );
        $grid->setSpacing('1unit');
    }

    if (defined $feintLines) {
        $feintGrid = My::Printable::Paper::Element::Grid->new(
            document  => $self->document,
            id        => 'feint-grid',
            cssClass  => $self->getFeintLineCSSClass,
            originX   => $grid->originX,
            originY   => $grid->originY,
            isDashedX => $feintDashedX,
            isDashedY => $feintDashedY,
            dashesX   => $feintDashedX,
            dashesY   => $feintDashedY,
        );
        $feintGrid->setSpacing('1/' . $feintLines . 'unit');
    }

    if (defined $majorGrid) {
        $self->document->appendElement($majorGrid);
    }
    $self->document->appendElement($grid);
    if (defined $feintGrid) {
        $self->document->appendElement($feintGrid);
    }

    $self->$orig();
};

1;
