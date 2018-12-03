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

    my $horizontal_lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        direction => 'horizontal',
        spacing => "1unit",
        cssStyle => 'stroke: #666666; stroke-width: {{ 1/600in }};',
    );

    my $vertical_dotted_lines = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-1',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1/6unit',
        cssClass => $self->getDotCSSClass,
        cssStyle => 'stroke: #666666; stroke-width: {{ 5/300in }}; stroke-linecap: butt;',
        dotHeight => '5/300in',
    );

    my $horizontal_dotted_lines_1 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-2',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY + $self->ptY('1/3unit'),
        cssClass => $self->getDotCSSClass,
        cssStyle => 'stroke: #666666; stroke-width: {{ 5/300in }}; stroke-linecap: butt;',
        dotWidth => '5/300in',
    );

    my $horizontal_dotted_lines_2 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-3',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY - $self->ptY('1/3unit'),
        cssClass => $self->getDotCSSClass,
        cssStyle => 'stroke: #666666; stroke-width: {{ 5/300in }}; stroke-linecap: butt;',
        dotWidth => '5/300in',
    );

    $self->document->appendElement($horizontal_lines);
    $self->document->appendElement($vertical_dotted_lines);
    $self->document->appendElement($horizontal_dotted_lines_1);
    $self->document->appendElement($horizontal_dotted_lines_2);

    $self->My::Printable::Ruling::generate();
}

1;
