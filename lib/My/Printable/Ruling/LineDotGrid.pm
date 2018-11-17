package My::Printable::Ruling::LineDotGrid;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base 'My::Printable::Ruling::Quadrille';

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use constant rulingName => 'line-dot-grid';

sub generate {
    my ($self) = @_;
    $self->document->setUnit($self->getUnit);

    my $grid = My::Printable::Element::Grid->new(
        document => $self->document,
        id => 'grid',
        cssClass => $self->getDotCSSClass,
    );
    $grid->isDotGrid(1);
    $grid->setSpacing('1unit');

    my $lines = My::Printable::Element::Lines->new(
        document => $self->document,
        id => 'lines',
        cssClass => $self->getLineCSSClass,
    );
    $lines->setSpacing('1unit');

    $self->document->appendElement($grid);
    $self->document->appendElement($lines);
    $self->document->generate;
}

sub getDotCSSClass {
    my ($self) = @_;
    my $thinner =
        $self->hasModifier->{'x-thinner-dots'} ? 2 :
        $self->hasModifier->{'thinner-dots'} ? 1 :
        0;
    my $thinner_class = ['semi-thick', '', 'semi-thin']->[$thinner];
    my $color_class   = $self->colorType eq 'grayscale' ? 'gray' : 'blue';
    return "$thinner_class $color_class dot";
}

sub getLineCSSClass {
    my ($self) = @_;
    my $thinner =
        $self->hasModifier->{'x-thinner-lines'} ? 2 :
        $self->hasModifier->{'thinner-lines'} ? 1 :
        0;
    my $thinner_class = ['thin', 'x-thin', 'xx-thin']->[$thinner];
    my $color_class   = $self->colorType eq 'grayscale' ? 'gray' : 'blue';
    return "$thinner_class $color_class line";
}

1;
