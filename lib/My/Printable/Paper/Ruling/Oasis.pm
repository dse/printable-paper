package My::Printable::Paper::Ruling::Oasis;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use Moo;

extends 'My::Printable::Paper::Ruling';

use My::Printable::Paper::Element::Grid;
use My::Printable::Paper::Element::Lines;
use My::Printable::Paper::Unit qw(:const);

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
        line.regular-dot {
            stroke-linecap: butt;
        }
        line.major-dot {
            stroke-linecap: butt;
        }
        line.feint-dot {
            stroke-linecap: butt;
        }
END
}

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $dotCrosswise  = $self->pt([$self->regularDotWidth(), 'pt']) . 'pt';
    my $dotCrosswise2 = $self->pt([2 * $self->regularDotWidth(), 'pt']) . 'pt';

    my $horizontal_lines = My::Printable::Paper::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        direction => 'horizontal',
        spacing => "1unit",
        cssClass => $self->getRegularLineCSSClass(),
    );

    my $vertical_dotted_lines = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid-1',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1/6unit',
        dotDashHeight => $dotCrosswise,
        cssClass => $self->getRegularDotCSSClass(),
    );

    my $horizontal_dotted_lines_1 = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid-2',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY + $self->ptY('1/3unit'),
        dotDashWidth => $dotCrosswise,
        cssClass => $self->getRegularDotCSSClass(),
    );

    my $horizontal_dotted_lines_2 = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid-3',
        isDotGrid => 1,
        spacingX => '1/7unit',
        spacingY => '1unit',
        originY => $self->originY - $self->ptY('1/3unit'),
        dotDashWidth => $dotCrosswise,
        cssClass => $self->getRegularDotCSSClass(),
    );

    my $grid_4 = My::Printable::Paper::Element::Grid->new(
        document => $self->document,
        id => 'grid-4',
        isDotGrid => 1,
        spacingX => '1unit',
        spacingY => '1unit',
        dotDashHeight => $dotCrosswise2,
        cssClass => $self->getRegularDotCSSClass(),
    );

    $self->document->appendElement($horizontal_lines);
    $self->document->appendElement($vertical_dotted_lines);
    $self->document->appendElement($horizontal_dotted_lines_1);
    $self->document->appendElement($horizontal_dotted_lines_2);
    $self->document->appendElement($grid_4);

    $self->$orig();
};

around 'getUnit' => sub {
    my ($orig, $self) = @_;
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
};

1;
