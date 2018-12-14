package My::Printable::Ruling::Oasis;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'oasis';
use constant dotThinness => 3;
use constant lineThinness => 4;

sub generate {
    my ($self) = @_;

    $self->document->setUnit($self->getUnit);

    my $color      = $self->colorType eq 'black' ? '#000000' : '#666666';
    my $colorClass = $self->colorType eq 'black' ? 'black' : 'gray40';

    my $horizontal_lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        direction => 'horizontal',
        spacing => "1unit",
        cssClass => "$colorClass stroke-2",
    );

    my $vertical_dotted_lines = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-1',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1/6unit',
        cssClass => $self->getDotCSSClass . " $colorClass stroke-6 stroke-linecap-butt",
        dotHeight => '3/300in',
    );

    my $horizontal_dotted_lines_1 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-2',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY + $self->ptY('1/3unit'),
        cssClass => $self->getDotCSSClass . " $colorClass stroke-6 stroke-linecap-butt",
        dotWidth => '3/300in',
    );

    my $horizontal_dotted_lines_2 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-3',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY - $self->ptY('1/3unit'),
        cssClass => $self->getDotCSSClass . " $colorClass stroke-6 stroke-linecap-butt",
        dotWidth => '3/300in',
    );

    my $grid_4 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-4',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1unit',
        cssClass => $self->getDotCSSClass . " $colorClass stroke-6 stroke-linecap-butt",
        dotHeight => '6/300in',
    );

    $self->document->appendElement($horizontal_lines);
    $self->document->appendElement($vertical_dotted_lines);
    $self->document->appendElement($horizontal_dotted_lines_1);
    $self->document->appendElement($horizontal_dotted_lines_2);
    $self->document->appendElement($grid_4);

    $self->My::Printable::Ruling::generate();
}

sub getUnit {
    my ($self) = @_;
    if ($self->unitType eq 'imperial') {
        if ($self->modifiers->has('denser-grid')) {
            return '1/4in';
        } else {
            return '3/10in';
        }
    } else {
        if ($self->modifiers->has('denser-grid')) {
            return '6mm';
        } else {
            return '23/3mm';
        }
    }
}

1;
