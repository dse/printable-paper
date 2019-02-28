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
    my $regularGrid;
    my $feintGrid;

    my $majorLinesX = $self->modifiers->get('major-lines-x') // $self->modifiers->get('major-lines');
    my $majorLinesY = $self->modifiers->get('major-lines-y') // $self->modifiers->get('major-lines');
    my $feintLines  = $self->modifiers->get('feint-lines');

    my $majorDashedX = $self->modifiers->get('major-dashed') // $self->modifiers->get('major-dashed-x');
    my $majorDashedY = $self->modifiers->get('major-dashed') // $self->modifiers->get('major-dashed-y');
    my $dashedX      = $self->modifiers->get('dashed')       // $self->modifiers->get('dashed-x');
    my $dashedY      = $self->modifiers->get('dashed')       // $self->modifiers->get('dashed-y');
    my $feintDashedX = $self->modifiers->get('feint-dashed') // $self->modifiers->get('feint-dashed-x');
    my $feintDashedY = $self->modifiers->get('feint-dashed') // $self->modifiers->get('feint-dashed-y');

    my $majorDotted = $self->modifiers->get('major-dotted');
    my $dotted      = $self->modifiers->get('dotted');
    my $feintDotted = $self->modifiers->get('feint-dotted');

    foreach my $value ($dashedX, $dashedY, $feintDashedX, $feintDashedY, $majorDotted, $dotted, $feintDotted) {
        if (defined $value && $value && $value eq 'yes') {
            $value = 1;
        }
    }

    # if dashed and dotted are specified, we're dashed and not dotted
    $dotted      = 0 if $dashedX      || $dashedY;
    $feintDotted = 0 if $feintDashedX || $feintDashedY;
    $majorDotted = 0 if $majorDashedX || $majorDashedY;

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
            isDashedX   => $majorDashedX,
            isDashedY   => $majorDashedY,
            dashesX     => $majorDashedX,
            dashesY     => $majorDashedY,
            isDotted    => $majorDotted,
            dotsX       => $majorDotted,
            dotsY       => $majorDotted,
        );
        $majorGrid->setSpacingX($majorLinesX . 'unit');
        $majorGrid->setSpacingY($majorLinesY . 'unit');

        $regularGrid = My::Printable::Paper::Element::Grid->new(
            document    => $self->document,
            id          => 'grid',
            cssClass    => $self->getRegularLineCSSClass,
            originX     => $majorGrid->originX,
            originY     => $majorGrid->originY,
            isDashedX   => $dashedX,
            isDashedY   => $dashedY,
            dashesX     => $dashedX,
            dashesY     => $dashedY,
            isDotted    => $dotted,
            dotsX       => $dotted,
            dotsY       => $dotted,
        );
        $regularGrid->setSpacing('1unit');
    } else {
        $regularGrid = My::Printable::Paper::Element::Grid->new(
            document    => $self->document,
            id          => 'grid',
            cssClass    => $self->getRegularLineCSSClass,
            shiftPoints => 1,
            isDashedX   => $dashedX,
            isDashedY   => $dashedY,
            dashesX     => $dashedX,
            dashesY     => $dashedY,
            isDotted    => $dotted,
            dotsX       => $dotted,
            dotsY       => $dotted,
        );
        $regularGrid->setSpacing('1unit');
    }

    if (defined $feintLines) {
        $feintGrid = My::Printable::Paper::Element::Grid->new(
            document  => $self->document,
            id        => 'feint-grid',
            cssClass  => $self->getFeintLineCSSClass,
            originX   => $regularGrid->originX,
            originY   => $regularGrid->originY,
            isDashedX => $feintDashedX,
            isDashedY => $feintDashedY,
            dashesX   => $feintDashedX,
            dashesY   => $feintDashedY,
            isDotted  => $feintDotted,
            dotsX     => $feintDotted,
            dotsY     => $feintDotted,
        );
        $feintGrid->setSpacing('1/' . $feintLines . 'unit');
    }

    if (defined $majorGrid) {
        $self->document->appendElement($majorGrid);
    }
    $self->document->appendElement($regularGrid);
    if (defined $feintGrid) {
        $self->document->appendElement($feintGrid);
    }

    if (defined $majorGrid) {
        $regularGrid->excludePointsFrom($majorGrid);
        if (defined $feintGrid) {
            $feintGrid->excludePointsFrom($majorGrid, $regularGrid);
        }
    } else {
        if (defined $feintGrid) {
            $feintGrid->excludePointsFrom($regularGrid);
        }
    }

    $self->$orig();
};

1;
