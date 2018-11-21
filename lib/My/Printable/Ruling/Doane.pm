package My::Printable::Ruling::Doane;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling';

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'doane';

sub generate {
    my ($self) = @_;
    $self->document->setUnit($self->getUnit);
    $self->document->setOriginX($self->getOriginX);

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getFeintLineCSSClass,
    );
    $grid->setSpacing('1/3unit');

    if ($self->hasModifier->{'denser-grid'}) {
        $grid->setOriginY('50%');
        $grid->setOriginY($grid->originY + $grid->ptY('1/3unit'));
    }

    my $lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        cssClass => $self->getLineCSSClass,
    );
    $lines->setSpacing('1unit');

    if ($self->hasModifier->{'denser-grid'}) {
        $lines->setOriginY('50%');
        $lines->setOriginY($lines->originY + $lines->ptY('1/3unit'));
    }

    my $margin_line = My::Printable::Element::Line->new(
        document => $self->document,
        id => 'margin-line',
        cssClass => $self->getMarginLineCSSClass,
    );
    $margin_line->setX($self->getOriginX);

    $self->document->appendElement($grid);
    $self->document->appendElement($lines);
    $self->document->appendElement($margin_line);
    $self->document->generate;
}

sub getUnit {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->hasModifier->{'denser-grid'}) {
            return '1/4in';
        } else {
            return '3/8in';
        }
    } else {
        if ($self->hasModifier->{'denser-grid'}) {
            return '6mm';
        } else {
            return '9mm';
        }
    }
}

sub getLineCSSClass {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return 'gray line';
    } else {
        return 'blue line';
    }
}

sub getFeintLineCSSClass {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return 'xx-thin gray line';
    } else {
        return 'xx-thin blue line';
    }
}

sub getOriginX {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        return '7/8in';
    } else {
        return '22mm';
    }
}

1;
