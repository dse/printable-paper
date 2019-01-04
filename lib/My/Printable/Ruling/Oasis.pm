package My::Printable::Ruling::Oasis;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Ruling';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;

use constant rulingName => 'oasis';
use constant dotThinness => 3;
use constant lineThinness => 4;

sub getDotColorCSSClassList {
    my ($self) = @_;
    return {
        color     => 'thin-blue',
        grayscale => 'thin-gray',
        black     => 'thin-black',
    }->{$self->colorType};
}
sub getLineColorCSSClassList {
    my ($self) = @_;
    return {
        color     => 'thin-blue',
        grayscale => 'thin-gray',
        black     => 'thin-black',
    }->{$self->colorType};
}
sub getMarginLineColorCSSClassList {
    my ($self) = @_;
    return {
        color     => 'thin-blue',
        grayscale => 'thin-gray',
        black     => 'thin-black',
    }->{$self->colorType};
}

sub getDotThicknessCSSClassList {
    my ($self) = @_;
    return {
        color     => 'stroke-4',
        grayscale => 'stroke-4',
        black     => 'stroke-6',
    }->{$self->colorType};
}
sub getLineThicknessCSSClassList {
    my ($self) = @_;
    return {
        color     => 'stroke-2',
        grayscale => 'stroke-2',
        black     => 'stroke-2',
    }->{$self->colorType};
    return 'stroke-2';
}
sub getMarginLineThicknessCSSClassList {
    my ($self) = @_;
    return {
        color     => 'stroke-4',
        grayscale => 'stroke-4',
        black     => 'stroke-6',
    }->{$self->colorType};
}

sub getDotTypeCSSClassList {
    my ($self) = @_;
    return 'line';
}
sub getLineTypeCSSClassList {
    my ($self) = @_;
    return 'line';
}
sub getMarginLineTypeCSSClassList {
    my ($self) = @_;
    return 'line';
}

sub generate {
    my ($self) = @_;

    $self->document->setUnit($self->getUnit);

    $self->document->additionalStyles(<<"END");
        #grid-1 line, #grid-1-pattern line {
            stroke-linecap: butt;
        }
        #grid-2 line, #grid-2-pattern line {
            stroke-linecap: butt;
        }
        #grid-3 line, #grid-3-pattern line {
            stroke-linecap: butt;
        }
        #grid-4 line, #grid-4-pattern line {
            stroke-linecap: butt;
        }
END

    my $horizontal_lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        direction => 'horizontal',
        spacing => "1unit",
        cssClass => $self->getLineCSSClass(),
    );

    my $vertical_dotted_lines = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-1',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1/6unit',
        dotHeight => '3/300in',
        cssClass => $self->getDotCSSClass(),
    );

    my $horizontal_dotted_lines_1 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-2',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY + $self->ptY('1/3unit'),
        dotWidth => '3/300in',
        cssClass => $self->getDotCSSClass(),
    );

    my $horizontal_dotted_lines_2 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-3',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY - $self->ptY('1/3unit'),
        dotWidth => '3/300in',
        cssClass => $self->getDotCSSClass(),
    );

    my $grid_4 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-4',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1unit',
        dotHeight => '6/300in',
        cssClass => $self->getDotCSSClass(),
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
            return '3/10in';    # close to 23/3mm
        }
    } else {
        if ($self->modifiers->has('denser-grid')) {
            return '6mm';
        } else {
            return '23/3mm';    # actual measured line height
        }
    }
}

1;
