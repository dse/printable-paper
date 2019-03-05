package My::Printable::Paper::Ruling::SeyesClass;
# subclass for Seyes and LineDotGraph.
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling';

sub getOriginX {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA6SizeClass()) {
            return '0.5in from left';
        } elsif ($self->isA5SizeClass()) {
            return '0.75in from left';
        } else {
            return '1.25in from left';
        }
    } else {
        if ($self->isA6SizeClass()) {
            return '12mm from left';
        } elsif ($self->isA5SizeClass()) {
            return '16mm from left';
        } else {
            return '41mm from left';
        }
    }
}

around getUnit => sub {
    my ($orig, $self) = @_;
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
};

sub getTopLineY {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA6SizeClass()) {
            return '0.75in from top';
        } elsif ($self->isA5SizeClass()) {
            return '1in from top';
        } else {
            return '1.5in from top';
        }
    } else {
        if ($self->isA6SizeClass()) {
            return '18mm from top';
        } elsif ($self->isA5SizeClass()) {
            return '24mm from top';
        } else {
            return '37mm from top';
        }
    }
}

sub getBottomLineY {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->isA6SizeClass()) {
            return '0.5in from bottom';
        } elsif ($self->isA5SizeClass()) {
            return '0.75in from bottom';
        } else {
            return '1in from bottom';
        }
    } else {
        if ($self->isA6SizeClass()) {
            return '14mm from bottom';
        } elsif ($self->isA5SizeClass()) {
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
    my $line = My::Printable::Paper::Element::Line->new(
        document => $self->document,
        id => 'head-line',
        cssClass => $self->getRegularLineCSSClass,
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
    my $line = My::Printable::Paper::Element::Line->new(
        document => $self->document,
        id => 'page-number-line',
        cssClass => $self->getRegularLineCSSClass,
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
