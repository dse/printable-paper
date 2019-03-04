package My::Printable::Paper::Ruling::Embry1;
# I hate naming things after myself.
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Element::Lines;

use Moo;

extends 'My::Printable::Paper::Ruling';

use constant rulingName => 'embry1';
# I hate naming things after myself.

around generateRuling => sub {
    my ($orig, $self) = @_;

    my $horizontalMajorLines = $self->modifiers->get('horizontal-major-lines') // 3;
    my $verticalFeintLines   = $self->modifiers->get('vertical-feint-lines') // 3;

    my $horizontalMajorDashed   = $self->modifiers->get('horizontal-major-dashed');
    my $horizontalRegularDashed = $self->modifiers->get('horizontal-regular-dashed');
    my $horizontalMajorDotted   = $self->modifiers->get('horizontal-major-dotted');
    my $horizontalRegularDotted = $self->modifiers->get('horizontal-regular-dotted');
    my $verticalRegularDashed   = $self->modifiers->get('vertical-regular-dashed');
    my $verticalFeintDashed     = $self->modifiers->get('vertical-feint-dashed');
    my $verticalRegularDotted   = $self->modifiers->get('vertical-regular-dotted');
    my $verticalFeintDotted     = $self->modifiers->get('vertical-feint-dotted');

    my $canShiftPointsY = !$self->hasMarginLine('top')  && !$self->hasMarginLine('bottom');

    say STDERR "canShiftPointsY = $canShiftPointsY";

    # $self->document->setClip('11/48in');
    $self->document->setClip('7.5/72in');

    foreach my $value ($horizontalMajorDashed, $horizontalRegularDashed,
                       $horizontalMajorDotted, $horizontalRegularDotted,
                       $verticalRegularDashed, $verticalFeintDashed,
                       $verticalRegularDotted, $verticalFeintDotted) {
        if (defined $value) {
            if ($value && $value eq 'yes') {
                $value = 1;
            } elsif ($value && $value eq 'no') {
                $value = 0;
            }
        }
    }

    $horizontalMajorDotted   = 0 if $horizontalMajorDashed;
    $horizontalRegularDotted = 0 if $horizontalRegularDashed;
    $verticalRegularDotted   = 0 if $verticalRegularDashed;
    $verticalFeintDotted     = 0 if $verticalFeintDashed;



    say STDERR "HORIZONTAL LINES";

    my $horizontalMajorLinesElement = My::Printable::Paper::Element::Lines->new(
        direction      => 'horizontal',
        document       => $self->document,
        id             => 'horizontal-major-lines',
        cssClass       => $self->getMajorLineCSSClass,
        isDashed       => $horizontalMajorDashed,
        isDotted       => $horizontalMajorDotted,
        dashes         => $horizontalMajorDashed,
        dots           => $horizontalMajorDotted,
        spacing        => '1unit',
        canShiftPoints => $canShiftPointsY,
    );
    if ($self->hasMarginLine('top')) {
        $horizontalMajorLinesElement->originY($self->getMarginLinePosition('top'));
    } elsif ($self->hasMarginLine('bottom')) {
        $horizontalMajorLinesElement->originY($self->getMarginLinePosition('bottom'));
    }
    if ($horizontalMajorDashed) {
        $horizontalMajorLinesElement->dashSpacing(sprintf('1/%dunit', $horizontalMajorDashed));
        # $horizontalMajorLinesElement->dashCenter($horizontalMajorLinesElement->originX);
    } elsif ($horizontalMajorDotted) {
        $horizontalMajorLinesElement->dotSpacing(sprintf('1/%dunit', $horizontalMajorDotted));
        # $horizontalMajorLinesElement->dotCenter($horizontalMajorLinesElement->originX);
    }

    say STDERR "computing <";
    $horizontalMajorLinesElement->compute();
    say STDERR ">";

    my $horizontalRegularLinesElement = My::Printable::Paper::Element::Lines->new(
        direction    => 'horizontal',
        document     => $self->document,
        id           => 'horizontal-regular-lines',
        cssClass     => $self->getRegularLineCSSClass,
        isDashed     => $horizontalRegularDashed,
        isDotted     => $horizontalRegularDotted,
        dashes       => $horizontalRegularDashed,
        dots         => $horizontalRegularDotted,
        spacing      => sprintf('1/%dunit', $horizontalMajorLines),
        originY      => $horizontalMajorLinesElement->yPointSeries->startPoint,
    );
    if ($horizontalRegularDashed) {
        $horizontalRegularLinesElement->dashSpacing(sprintf('1/%dunit', $horizontalRegularDashed * $horizontalMajorLines));
        # $horizontalRegularLinesElement->dashCenter($horizontalRegularLinesElement->originX);
    } elsif ($horizontalRegularDotted) {
        $horizontalRegularLinesElement->dotSpacing(sprintf('1/%dunit', $horizontalRegularDotted * $horizontalMajorLines));
        # $horizontalRegularLinesElement->dotCenter($horizontalRegularLinesElement->originX);
    }

    say STDERR "computing <";
    $horizontalRegularLinesElement->compute();
    say STDERR ">";



    say STDERR "VERTICAL LINES";

    my $canShiftPointsX = !$self->hasMarginLine('left') && !$self->hasMarginLine('right');
    say STDERR "canShiftPointsX = $canShiftPointsX";

    my $verticalRegularLinesElement = My::Printable::Paper::Element::Lines->new(
        direction      => 'vertical',
        document       => $self->document,
        id             => 'vertical-regular-lines',
        cssClass       => $self->getRegularLineCSSClass,
        isDashed       => $verticalRegularDashed,
        isDotted       => $verticalRegularDotted,
        dashes         => $verticalRegularDashed,
        dots           => $verticalRegularDotted,
        spacing        => '1unit',
        canShiftPoints => $canShiftPointsX,
    );
    if ($self->hasMarginLine('left')) {
        $verticalRegularLinesElement->originX($self->getMarginLinePosition('left'));
    } elsif ($self->hasMarginLine('right')) {
        $verticalRegularLinesElement->originX($self->getMarginLinePosition('right'));
    }
    if ($verticalRegularDashed) {
        $verticalRegularLinesElement->dashSpacing(sprintf('1/%dunit', $verticalRegularDashed));
        # $verticalRegularLinesElement->dashCenter($verticalRegularLinesElement->originY);
    } elsif ($verticalRegularDotted) {
        $verticalRegularLinesElement->dotSpacing(sprintf('1/%dunit', $verticalRegularDotted));
        # $verticalRegularLinesElement->dotCenter($verticalRegularLinesElement->originY);
    }

    say STDERR "computing <";
    $verticalRegularLinesElement->compute();
    say STDERR ">";

    my $verticalFeintLinesElement = My::Printable::Paper::Element::Lines->new(
        direction    => 'vertical',
        document     => $self->document,
        id           => 'vertical-feint-lines',
        cssClass     => $self->getFeintLineCSSClass,
        isDashed     => $verticalFeintDashed,
        isDotted     => $verticalFeintDotted,
        dashes       => $verticalFeintDashed,
        dots         => $verticalFeintDotted,
        spacing      => sprintf('1/%dunit', $verticalFeintLines),
        originX      => $verticalRegularLinesElement->xPointSeries->startPoint,
    );
    if ($verticalFeintDashed) {
        $verticalFeintLinesElement->dashSpacing(sprintf('1/%dunit', $verticalFeintDashed * $verticalFeintLines));
        # $verticalFeintLinesElement->dashCenter($verticalFeintLinesElement->originY);
    } elsif ($verticalFeintDotted) {
        $verticalFeintLinesElement->dotSpacing(sprintf('1/%dunit', $verticalFeintDotted * $verticalFeintLines));
        # $verticalFeintLinesElement->dotCenter($verticalFeintLinesElement->originY);
    }

    say STDERR "computing <";
    $verticalFeintLinesElement->compute();
    say STDERR ">";



    say STDERR "originY = ", $horizontalMajorLinesElement->originY // '(undef)';
    say STDERR "originX = ", $verticalRegularLinesElement->originX // '(undef)';
    say STDERR "yPointSeries = ", $horizontalMajorLinesElement->yPointSeries // '(undef)';
    say STDERR "xPointSeries = ", $verticalRegularLinesElement->xPointSeries // '(undef)';

    $self->document->appendElement($horizontalMajorLinesElement);
    $self->document->appendElement($horizontalRegularLinesElement);
    $self->document->appendElement($verticalRegularLinesElement);
    $self->document->appendElement($verticalFeintLinesElement);

    $self->$orig();
};


1;
