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
public "dottedLineXValues", default => [];
public "dottedLineYValues", default => [];
public "origDottedLineXValues", default => [];
public "origDottedLineYValues", default => [];

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(get_series_of_points);

use base qw(My::Printable::Element);

use List::Util qw(min max);

sub computeX {
    my ($self) = @_;
    $self->SUPER::computeX();
    if ($self->isDottedLineGrid) {
        my $spacing = scalar($self->spacingX // $self->spacing // $self->ptX("1unit"));
        $spacing /= $self->horizontalDots;
        my @xValues = get_series_of_points(
            spacing => $spacing,
            min     => scalar($self->leftX // $self->leftMarginX),
            max     => scalar($self->rightX // $self->rightMarginX),
            origin  => scalar($self->originX // ($self->width / 2)),
        );
        $self->dottedLineXValues([@xValues]);
        $self->origDottedLineXValues([@xValues]);
    }
}

sub computeY {
    my ($self) = @_;
    $self->SUPER::computeY();
    if ($self->isDottedLineGrid) {
        my $spacing = scalar($self->spacingY // $self->spacing // $self->ptY("1unit"));
        $spacing /= $self->verticalDots;
        my @yValues = get_series_of_points(
            spacing => $spacing,
            min     => scalar($self->bottomY // $self->bottomMarginY),
            max     => scalar($self->topY    // $self->topMarginY),
            origin  => scalar($self->originY // ($self->height / 2)),
        );
        $self->dottedLineYValues([@yValues]);
        $self->origDottedLineYValues([@yValues]);
    }
}

sub chopX {
    my ($self) = @_;
    $self->SUPER::chopX();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        my $x = $self->dottedLineXValues;
        if (defined $x) {
            # float
            @$x = grep { $_ >= $self->leftX   } @$x if defined $self->leftX;
            @$x = grep { $_ <= $self->rightX  } @$x if defined $self->rightX;
        }
    }
}

sub chopY {
    my ($self) = @_;
    $self->SUPER::chopY();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        my $y = $self->dottedLineYValues;
        if (defined $y) {
            # float
            @$y = grep { $_ >= $self->bottomY } @$y if defined $self->bottomY;
            @$y = grep { $_ <= $self->topY    } @$y if defined $self->topY;
        }
    }
}

sub excludeX {
    my ($self, @id) = @_;
    $self->SUPER::excludeX();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        my $x = $self->dottedLineXValues;
        if (defined $x) {
            # float
            @$x = grep { $_ >= $self->leftMarginX   } @$x if defined $self->leftMarginX;
            @$x = grep { $_ <= $self->rightMarginX  } @$x if defined $self->rightMarginX;

            foreach my $id (@id) {
                my $element = $self->elements->{$id};
                next unless $element;

                # TODO
            }
        }
    }
}

sub excludeY {
    my ($self, @id) = @_;
    $self->SUPER::excludeY();

    if ($self->isEnclosed && $self->isDottedLineGrid) {
        my $y = $self->dottedLineYValues;
        if (defined $y) {
            # float
            @$y = grep { $_ >= $self->bottomMarginY } @$y if defined $self->bottomMarginY;
            @$y = grep { $_ <= $self->topMarginY    } @$y if defined $self->topMarginY;

            foreach my $id (@id) {
                my $element = $self->elements->{$id};
                next unless $element;

                # TODO
            }
        }
    }
}

sub draw {
    my ($self) = @_;
    my $x1 = $self->leftMarginX;
    my $x2 = $self->rightMarginX;
    my $y1 = $self->bottomMarginY;
    my $y2 = $self->topMarginY;
    if ($self->isDottedLineGrid) {

        if ($self->isEnclosed) {
            $x1 = min(@{$self->xValues});
            $x2 = max(@{$self->xValues});
            $y1 = min(@{$self->yValues});
            $y2 = max(@{$self->yValues});
        }

        # vertical dotted lines
        foreach my $x (@{$self->xValues}) {
            foreach my $y (@{$self->dottedLineYValues}) {
                my $cssClass = $self->cssClassVertical // $self->cssClass // "blue dot";
                my $line = $self->createSVGLine(x => $x, y => $y, cssClass => $cssClass);
                $self->appendSVGLine($line);
            }
        }

        # horizontal dotted lines
        foreach my $y (@{$self->yValues}) {
            foreach my $x (@{$self->dottedLineXValues}) {
                my $cssClass = $self->cssClassHorizontal // $self->cssClass // "blue dot";
                my $line = $self->createSVGLine(x => $x, y => $y, cssClass => $cssClass);
                $self->appendSVGLine($line);
            }
        }

    } elsif ($self->isDotGrid) {
        foreach my $x (@{$self->xValues}) {
            foreach my $y (@{$self->yValues}) {
                my $cssClass = $self->cssClass // "blue dot";
                my $line = $self->createSVGLine(x => $x, y => $y, cssClass => $cssClass);
                $self->appendSVGLine($line);
            }
        }
    } else {
        if ($self->isEnclosed) {
            $x1 = min(@{$self->xValues});
            $x2 = max(@{$self->xValues});
            $y1 = min(@{$self->yValues});
            $y2 = max(@{$self->yValues});
        }

        # vertical lines
        foreach my $x (@{$self->xValues}) {
            my $cssClass = $self->cssClassVertical // $self->cssClass // "thin blue line";
            my $line = $self->createSVGLine(x => $x, y1 => $y1, y2 => $y2, cssClass => $cssClass);
            $self->appendSVGLine($line);
        }

        # horizontal lines
        foreach my $y (@{$self->yValues}) {
            my $cssClass = $self->cssClassHorizontal // $self->cssClass // "thin blue line";
            my $line = $self->createSVGLine(y => $y, x1 => $x1, x2 => $x2, cssClass => $cssClass);
            $self->appendSVGLine($line);
        }
    }
}

1;
