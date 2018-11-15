package My::Printable::Element::Grid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public "cssClassHorizontal";
public "cssClassVertical";
public "isDotGrid", default => 0;
public "isEnclosed", default => 0;
public "isDottedLineGrid", default => 0;

public "horizontalDots", default => 2;
public "verticalDots", default => 2;

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
    if ($self->isDottedLineGrid) {
        my $spacing = scalar($self->spacingX // $self->spacing // $self->ptX("1unit"));
        $spacing /= $self->horizontalDots;
        $self->dottedLineXPointSeries(My::Printable::PointSeries->new(
            spacing => $spacing,
            min     => scalar($self->leftX // $self->leftMarginX),
            max     => scalar($self->rightX // $self->rightMarginX),
            origin  => scalar($self->originX // ($self->width / 2)),
        ));
        $self->origDottedLineXPointSeries(dclone($self->dottedLineXPointSeries));
    }
}

sub computeY {
    my ($self) = @_;
    $self->SUPER::computeY();
    if ($self->isDottedLineGrid) {
        my $spacing = scalar($self->spacingY // $self->spacing // $self->ptY("1unit"));
        $spacing /= $self->verticalDots;
        $self->dottedLineYPointSeries(My::Printable::PointSeries->new(
            spacing => $spacing,
            min     => scalar($self->topY    // $self->topMarginY),
            max     => scalar($self->bottomY // $self->bottomMarginY),
            origin  => scalar($self->originY // ($self->height / 2)),
        ));
        $self->origDottedLineYPointSeries(dclone($self->dottedLineYPointSeries));
    }
}

sub chopX {
    my ($self) = @_;
    $self->SUPER::chopX();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        $self->xPointSeries->chopBehind($self->leftX);
        $self->xPointSeries->chopAhead($self->rightX);
    }
}

sub chopY {
    my ($self) = @_;
    $self->SUPER::chopY();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        $self->yPointSeries->chopBehind($self->topY);
        $self->yPointSeries->chopAhead($self->bottomY);
    }
}

sub chopMarginsX {
    my ($self) = @_;
    $self->SUPER::chopMarginsX();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        $self->xPointSeries->chopBehind($self->leftMarginX);
        $self->xPointSeries->chopAhead($self->rightMarginX);
    }
}

sub chopMarginsY {
    my ($self) = @_;
    $self->SUPER::chopMarginsY();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        $self->yPointSeries->chopBehind($self->topMarginY);
        $self->yPointSeries->chopAhead($self->bottomMarginY);
    }
}

sub draw {
    my ($self) = @_;

    my $x1 = $self->xPointSeries->min;
    my $x2 = $self->xPointSeries->max;
    my $y1 = $self->yPointSeries->min;
    my $y2 = $self->yPointSeries->max;

    if ($self->isDottedLineGrid) {

        # vertical dotted lines
        $self->drawDotPattern(
            cssClass => ($self->cssClassVertical // $self->cssClass // "blue dot"),
            xPointSeries => $self->xPointSeries,
            yPointSeries => $self->dottedLineYPointSeries,
            x1 => $x1,
            x2 => $x2,
            y1 => $y1,
            y2 => $y2,
        );

        # horizontal dotted lines
        $self->drawDotPattern(
            cssClass => ($self->cssClassHorizontal // $self->cssClass // "blue dot"),
            xPointSeries => $self->dottedLineXPointSeries,
            yPointSeries => $self->yPointSeries,
            x1 => $x1,
            x2 => $x2,
            y1 => $y1,
            y2 => $y2,
        );

    } elsif ($self->isDotGrid) {
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
        $self->drawVerticalLinePattern(
            cssClass => ($self->cssClassVertical // $self->cssClass // "thin blue line"),
            xPointSeries => $self->xPointSeries,
            y1 => $y1,
            y2 => $y2,
        );
        $self->drawHorizontalLinePattern(
            cssClass => ($self->cssClassHorizontal // $self->cssClass // "thin blue line"),
            yPointSeries => $self->yPointSeries,
            x1 => $x1,
            x2 => $x2,
        );
    }
}

1;
