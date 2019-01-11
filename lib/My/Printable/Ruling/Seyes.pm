package My::Printable::Ruling::Seyes;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Ruling';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;
use My::Printable::Element::Line;

use POSIX qw(round);

use constant rulingName => 'seyes';
use constant hasLineGrid => 1;
use constant hasMarginLine => 1;

sub generate {
    my ($self) = @_;

    $self->document->setUnit($self->getUnit);
    $self->document->originX($self->getOriginX);
    $self->document->originY($self->getOriginY);

    my $dividingLines = $self->modifiers->get('dividing-lines') || $self->modifiers->get('feint-lines');

    $dividingLines = round($dividingLines);
    $dividingLines = undef if $dividingLines < 2;

    my $grid = My::Printable::Element::Grid->new(
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

    my $lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        cssClass => $self->getLineCSSClass,
    );
    $lines->setY1($self->getTopLineY);
    $lines->setY2($self->getBottomLineY);
    $lines->setSpacing('1unit');

    $self->document->appendElement($grid);
    $self->document->appendElement($lines);

    $self->My::Printable::Ruling::generate();
}

sub getOriginX {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA5SizeClass()) {
            return '0.75in from left';
        } else {
            return '1.25in from left';
        }
    } else {
        if ($self->isA5SizeClass()) {
            return '16mm from left';
        } else {
            return '41mm from left';
        }
    }
}

sub getRulingSpecificUnit {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->modifiers->has('10mm')) {
            return '3/8in';
        } elsif ($self->modifiers->has('three-line')) {
            return '1/4in';
        } else {
            return '5/16in';
        }
    } else {
        if ($self->modifiers->has('10mm')) {
            return '10mm';
        } elsif ($self->modifiers->has('three-line')) {
            return '6mm';
        } else {
            return '8mm';
        }
    }
}

sub getTopLineY {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA5SizeClass()) {
            return '1in from top';
        } else {
            return '1.5in from top';
        }
    } else {
        if ($self->isA5SizeClass()) {
            return '24mm from top';
        } else {
            return '37mm from top';
        }
    }
}

sub getBottomLineY {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA5SizeClass()) {
            return '0.75in from bottom';
        } else {
            return '1in from bottom';
        }
    } else {
        if ($self->isA5SizeClass()) {
            return '19mm from bottom';
        } else {
            return '28mm from bottom';
        }
    }
}

sub getOriginY {
    my ($self) = @_;
    return $self->getTopLineY;
}

sub generateHeadLine {
    my ($self) = @_;
    my $line = My::Printable::Element::Line->new(
        document => $self->document,
        id => 'head-line',
        cssClass => $self->getLineCSSClass,
    );
    $line->setY($self->getHeadLineY);
    return $line;
}

sub getHeadLineY {
    my ($self) = @_;
    return '0.5in' if $self->unitType eq 'imperial';
    return '12mm';
}

sub generatePageNumberLine {
    my ($self, %args) = @_;
    my $line = My::Printable::Element::Line->new(
        document => $self->document,
        id => 'page-number-line',
        cssClass => $self->getLineCSSClass,
    );
    $line->setY($self->getPageNumberLineY);
    if ($self->modifiers->has('even-page')) {
        $line->setX2($self->getOriginX);
        $line->setWidth('3unit');
    } else {
        $line->setX2('1unit from right');
        if ($args{nearest}) {
            $args{nearest}->compute();
            $line->setX2($args{nearest}->nearestX($line->x2));
        }
        $line->setWidth('3unit');
    }
    return $line;
}

sub getPageNumberLineY {
    my ($self) = @_;
    return '0.25in from bottom' if $self->unitType eq 'imperial';
    return '6mm from bottom';
}

1;
