package My::Printable::Ruling::Oasis;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Ruling';

use My::Printable::Element::Grid;
use My::Printable::Element::Lines;
use My::Printable::Unit qw(:const);

use constant rulingName => 'oasis';

sub baseLineWidth {
    my ($self) = @_;
    return 1 * PD if $self->colorType eq 'black';
    return 4 * PD;
}

sub baseDotWidth {
    my ($self) = @_;
    return 2 * PD if $self->colorType eq 'black';
    return 4 * PD;
}

sub additionalCSS {
    my ($self) = @_;
    return <<"END";
        line.dot {
            stroke-linecap: butt;
        }
END
}

sub generate {
    my ($self) = @_;

    $self->document->setUnit($self->getUnit);

    warn($self->getDotWidth());

    my $dotCrosswise  = $self->pt([$self->getDotWidth(), 'pt']) . 'pt';
    my $dotCrosswise2 = $self->pt([2 * $self->getDotWidth(), 'pt']) . 'pt';
    warn($dotCrosswise);
    warn($dotCrosswise2);

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
        dotHeight => $dotCrosswise,
        cssClass => $self->getDotCSSClass(),
    );

    my $horizontal_dotted_lines_1 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-2',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY + $self->ptY('1/3unit'),
        dotWidth => $dotCrosswise,
        cssClass => $self->getDotCSSClass(),
    );

    my $horizontal_dotted_lines_2 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-3',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY - $self->ptY('1/3unit'),
        dotWidth => $dotCrosswise,
        cssClass => $self->getDotCSSClass(),
    );

    my $grid_4 = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid-4',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1unit',
        dotHeight => $dotCrosswise2,
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
