package My::Printable::Paper::Element::Grid;
use warnings;
use strict;
use v5.10.0;

use Moo;

has "cssClassHorizontal" => (is => 'rw');
has "cssClassVertical" => (is => 'rw');

has "isDotGrid" => (is => 'rw', default => 0);
has "hasDottedGridLines" => (is => 'rw', default => 0);
has "hasDottedHorizontalGridLines" => (is => 'rw', default => 0);
has "hasDottedVerticalGridLines" => (is => 'rw', default => 0);
has "extendGridLines" => (is => 'rw', default => 0);
has "extendHorizontalGridLines" => (is => 'rw', default => 0);
has "extendVerticalGridLines" => (is => 'rw', default => 0);

# for dotted line grids
has "horizontalDots" => (is => 'rw', default => 2);
has "verticalDots" => (is => 'rw', default => 2);

has "dottedLineXPointSeries" => (is => 'rw');
has "dottedLineYPointSeries" => (is => 'rw');
has "origDottedLineXPointSeries" => (is => 'rw');
has "origDottedLineYPointSeries" => (is => 'rw');

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::PointSeries;

use Moo;

extends qw(My::Printable::Paper::Element);

use List::Util qw(min max);
use Storable qw(dclone);
use Text::Util qw(grid);

sub computeX {
    my ($self) = @_;
    $self->SUPER::computeX();

    if ($self->hasDottedGridLines || $self->hasDottedHorizontalGridLines) {
        my $spacingX = $self->spacingX // $self->spacing // $self->ptX("1unit");
        $spacingX /= $self->horizontalDots;
        my $originX = $self->originX // $self->document->originX;

        $self->dottedLineXPointSeries(My::Printable::Paper::PointSeries->new(
            spacing => $spacingX,
            min     => scalar($self->x1 // $self->document->leftMarginX),
            max     => scalar($self->x2 // $self->document->rightMarginX),
            origin  => $originX,
        ));
        $self->origDottedLineXPointSeries(My::Printable::Paper::PointSeries->new(
            spacing => $spacingX,
            min     => scalar($self->document->leftMarginX),
            max     => scalar($self->document->rightMarginX),
            origin  => $originX,
        ));
    }
}

sub computeY {
    my ($self) = @_;
    $self->SUPER::computeY();

    if ($self->hasDottedGridLines || $self->hasDottedVerticalGridLines) {
        my $spacingY = scalar($self->spacingY // $self->spacing // $self->ptY("1unit"));
        $spacingY /= $self->verticalDots;
        my $originY = $self->originY // $self->document->originY;

        $self->dottedLineYPointSeries(My::Printable::Paper::PointSeries->new(
            spacing => $spacingY,
            min     => scalar($self->y1 // $self->document->topMarginY),
            max     => scalar($self->y2 // $self->document->bottomMarginY),
            origin  => $originY,
        ));
        $self->origDottedLineYPointSeries(My::Printable::Paper::PointSeries->new(
            spacing => $spacingY,
            min     => scalar($self->document->topMarginY),
            max     => scalar($self->document->bottomMarginY),
            origin  => $originY,
        ));
    }
}

sub chopX {
    my ($self) = @_;
    $self->SUPER::chopX();

    if ($self->dottedLineXPointSeries) {
        $self->dottedLineXPointSeries->chopBehind($self->document->leftMarginX);
        $self->dottedLineXPointSeries->chopAhead($self->document->rightMarginX);
    }
}

sub chopY {
    my ($self) = @_;
    $self->SUPER::chopY();

    if ($self->dottedLineYPointSeries) {
        $self->dottedLineYPointSeries->chopBehind($self->document->topMarginY);
        $self->dottedLineYPointSeries->chopAhead($self->document->bottomMarginY);
    }
}

sub draw {
    my ($self) = @_;

    my $x1 = $self->x1 // $self->document->leftMarginX;
    my $x2 = $self->x2 // $self->document->rightMarginX;
    my $y1 = $self->y1 // $self->document->topMarginY;
    my $y2 = $self->y2 // $self->document->bottomMarginY;

    if ($self->isDotGrid) {
        my $cssClass = $self->cssClass // "blue dot";
        $self->drawDotPattern(
            cssClass => $cssClass,
            xPointSeries => $self->xPointSeries,
            yPointSeries => $self->yPointSeries,
            x1 => $x1,
            x2 => $x2,
            y1 => $y1,
            y2 => $y2,
        );
    } else {

        # horizontal grid lines
        if ($self->hasDottedGridLines || $self->hasDottedHorizontalGridLines) {
            my $xLinePointSeries = ($self->extendHorizontalGridLines || $self->extendGridLines) ? $self->origDottedLineXPointSeries : $self->dottedLineXPointSeries;
            my @x = $xLinePointSeries->getPoints();
            my $cssClass = $self->cssClassHorizontal // $self->cssClass // "blue dot";
            $cssClass = trim(($cssClass // '') . ' horizontal');
            $self->drawDotPattern(
                cssClass => $cssClass,
                xPointSeries => $xLinePointSeries,
                yPointSeries => $self->yPointSeries,
                x1 => $x1,
                x2 => $x2,
                y1 => $y1,
                y2 => $y2,
            );
        } else {
            if ($self->extendHorizontalGridLines || $self->extendGridLines) {
                $x1 = $self->document->leftMarginX;
                $x2 = $self->document->rightMarginX;
            }
            my $cssClass = $self->cssClassHorizontal // $self->cssClass // "thin blue line";
            $self->drawHorizontalLinePattern(
                cssClass => $cssClass,
                yPointSeries => $self->yPointSeries,
                x1 => $x1,
                x2 => $x2,
            );
        }

        # vertical grid lines
        if ($self->hasDottedGridLines || $self->hasDottedVerticalGridLines) {
            my $yLinePointSeries = ($self->extendVerticalGridLines || $self->extendGridLines) ? $self->origDottedLineYPointSeries : $self->dottedLineYPointSeries;
            my @y = $yLinePointSeries->getPoints();
            my $cssClass = $self->cssClassVertical // $self->cssClass // "blue dot";
            $cssClass = trim(($cssClass // '') . ' vertical');
            $self->drawDotPattern(
                cssClass => $cssClass,
                xPointSeries => $self->xPointSeries,
                yPointSeries => $yLinePointSeries,
                x1 => $x1,
                x2 => $x2,
                y1 => $y1,
                y2 => $y2,
            );
        } else {
            if ($self->extendVerticalGridLines || $self->extendGridLines) {
                $y1 = $self->document->topMarginY;
                $y2 = $self->document->bottomMarginY;
            }
            my $cssClass = $self->cssClassVertical // $self->cssClass // "thin blue line";
            $self->drawVerticalLinePattern(
                cssClass => $cssClass,
                xPointSeries => $self->xPointSeries,
                y1 => $y1,
                y2 => $y2,
            );
        }
    }
}

1;
