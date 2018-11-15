package My::Printable::Element::Grid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public "cssClassHorizontal";
public "cssClassVertical";

public "isDotGrid",                 default => 0;
public "hasDottedGridLines",           default => 0;
public "hasDottedHorizontalGridLines", default => 0;
public "hasDottedVerticalGridLines",   default => 0;
public "extendGridLines",           default => 0;
public "extendHorizontalGridLines", default => 0;
public "extendVerticalGridLines",   default => 0;

# for dotted line grids
public "horizontalDots",            default => 2;
public "verticalDots",              default => 2;

public "dottedLineXPointSeries";
public "dottedLineYPointSeries";
public "origDottedLineXPointSeries";
public "origDottedLineYPointSeries";

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(get_series_of_points
                           get_point_series);
use My::Printable::PointSeries;

use base qw(My::Printable::Element);

use List::Util qw(min max);
use Storable qw(dclone);

sub computeX {
    my ($self) = @_;
    $self->SUPER::computeX();

    if ($self->hasDottedGridLines || $self->hasDottedHorizontalGridLines) {
        my $spacingX = $self->spacingX // $self->spacing // $self->ptX("1unit");
        $spacingX /= $self->horizontalDots;
        my $originX = $self->originX // $self->document->originX;

        $self->dottedLineXPointSeries(My::Printable::PointSeries->new(
            spacing => $spacingX,
            min     => scalar($self->x1 // $self->document->leftMarginX),
            max     => scalar($self->x2 // $self->document->rightMarginX),
            origin  => $originX,
        ));
        $self->origDottedLineXPointSeries(My::Printable::PointSeries->new(
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

        $self->dottedLineYPointSeries(My::Printable::PointSeries->new(
            spacing => $spacingY,
            min     => scalar($self->y1 // $self->document->topMarginY),
            max     => scalar($self->y2 // $self->document->bottomMarginY),
            origin  => $originY,
        ));
        $self->origDottedLineYPointSeries(My::Printable::PointSeries->new(
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
        if ($self->hasDottedGridLines || $self->hasDottedHorizontalGridLines) {
            my $xLinePointSeries = ($self->extendHorizontalGridLines || $self->extendGridLines) ? $self->origDottedLineXPointSeries : $self->dottedLineXPointSeries;
            my @x = $xLinePointSeries->getPoints();
            $self->drawDotPattern(
                cssClass => ($self->cssClassHorizontal // $self->cssClass // "blue dot"),
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
            $self->drawHorizontalLinePattern(
                cssClass => ($self->cssClassHorizontal // $self->cssClass // "thin blue line"),
                yPointSeries => $self->yPointSeries,
                x1 => $x1,
                x2 => $x2,
            );
        }
        if ($self->hasDottedGridLines || $self->hasDottedVerticalGridLines) {
            my $yLinePointSeries = ($self->extendVerticalGridLines || $self->extendGridLines) ? $self->origDottedLineYPointSeries : $self->dottedLineYPointSeries;
            my @y = $yLinePointSeries->getPoints();
            $self->drawDotPattern(
                cssClass => ($self->cssClassVertical // $self->cssClass // "blue dot"),
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
            $self->drawVerticalLinePattern(
                cssClass => ($self->cssClassVertical // $self->cssClass // "thin blue line"),
                xPointSeries => $self->xPointSeries,
                y1 => $y1,
                y2 => $y2,
            );
        }
    }
}

1;
