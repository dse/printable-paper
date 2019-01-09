package My::Printable::Ruling;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Document;
use My::Printable::Element::Rectangle;
use My::Printable::Unit qw(:const);
use My::Printable::Color qw(:const);

use Moo;

has 'document' => (
    is => 'rw',
    default => sub {
        return My::Printable::Document->new();
    },
    clearer => 'deleteDocument',
    handles => [
        'id',
        'filename',
        'paperSizeName',
        'width',
        'height',
        'modifiers',
        'unitType',
        'colorType',
        'print',
        'printToFile',
        'isA4SizeClass',
        'isA5SizeClass',
        'ptX',
        'ptY',
        'pt',
        'originX',
        'originY',
        'dryRun',
        'verbose',
        'generatePS',
        'generatePDF',
        'generate2Page',
        'generate2Up',
    ],
);

use constant rulingName => 'none';
use constant hasLineGrid => 0;
use constant hasMarginLine => 0;
use constant hasPageNumberRectangle => 0;

use Text::Trim qw(trim);

sub thicknessCSS {
    my ($self) = @_;
    my $lw  = $self->lineWidth;
    my $flw = $self->feintLineWidth;
    my $dw  = $self->dotWidth;
    my $mlw = $self->marginLineWidth;

    my $lo = 1;
    my $flo = 1;
    my $do = 1;
    my $mlo = 1;

    if ($lw < PD)  { $lo  = $lw / PD;  $lw  = PD; }
    if ($flw < PD) { $flo = $flw / PD; $flw = PD; }
    if ($dw < PD)  { $do  = $dw / PD;  $dw  = PD; }
    if ($mlw < PD) { $mlo = $mlw / PD; $mlw = PD; }

    return <<"EOF";
        .line        { stroke-width: {{  ${lw} pt }}; opacity: ${lo}; }
        .feint-line  { stroke-width: {{ ${flw} pt }}; opacity: ${flo}; }
        .dot         { stroke-width: {{  ${dw} pt }}; opacity: ${do}; }
        .margin-line { stroke-width: {{ ${mlw} pt }}; opacity: ${mlo}; }
EOF
}

has 'rawLineColor'       => (is => 'rw');
has 'rawFeintLineColor'  => (is => 'rw');
has 'rawDotColor'        => (is => 'rw');
has 'rawMarginLineColor' => (is => 'rw');

sub defaultLineColor {
    my ($self) = @_;
    return COLOR_BLUE if $self->colorType eq 'color';
    return COLOR_GRAY if $self->colorType eq 'grayscale';
    return COLOR_BLACK;
}
sub defaultFeintLineColor {
    my ($self) = @_;
    return COLOR_BLUE if $self->colorType eq 'color';
    return COLOR_GRAY if $self->colorType eq 'grayscale';
    return COLOR_BLACK;
}
sub defaultDotColor {
    my ($self) = @_;
    return COLOR_BLUE if $self->colorType eq 'color';
    return COLOR_GRAY if $self->colorType eq 'grayscale';
    return COLOR_BLACK;
}
sub defaultMarginLineColor {
    my ($self) = @_;
    return COLOR_RED  if $self->colorType eq 'color';
    return COLOR_GRAY if $self->colorType eq 'grayscale';
    return COLOR_BLACK;
}

sub lineColor {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawLineColor) {
            return $self->defaultLineColor;
        }
        return $self->rawLineColor->asHex;
    }
    my $value = shift;
    return $self->rawLineColor(
        My::Printable::Color->new($value)
    )->asHex;
}

sub feintLineColor {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawFeintLineColor) {
            return $self->defaultFeintLineColor;
        }
        return $self->rawFeintLineColor->asHex;
    }
    my $value = shift;
    return $self->rawFeintLineColor(
        My::Printable::Color->new($value)
    )->asHex;
}

sub dotColor {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawDotColor) {
            return $self->defaultDotColor;
        }
        return $self->rawDotColor->asHex;
    }
    my $value = shift;
    return $self->rawDotColor(
        My::Printable::Color->new($value)
    )->asHex;
}

sub marginLineColor {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawMarginLineColor) {
            return $self->defaultMarginLineColor;
        }
        return $self->rawMarginLineColor->asHex;
    }
    my $value = shift;
    return $self->rawMarginLineColor(
        My::Printable::Color->new($value)
    )->asHex;
}

sub colorCSS {
    my ($self) = @_;

    my $lineColor       = $self->lineColor;
    my $feintLineColor  = $self->feintLineColor;
    my $dotColor        = $self->dotColor;
    my $marginLineColor = $self->marginLineColor;

    return <<"EOF";
        .line        { stroke: $lineColor; }
        .feint-line  { stroke: $feintLineColor; }
        .dot         { stroke: $dotColor; }
        .margin-line { stroke: $marginLineColor; }
EOF
}

sub additionalCSS {
    my ($self) = @_;
    return undef;
}

sub generate {
    my ($self) = @_;
    if ($self->hasPageNumberRectangle) {
        $self->document->appendElement(
            $self->generatePageNumberRectangle()
        );
    }
    if ($self->hasMarginLine) {
        $self->document->appendElement(
            $self->generateMarginLine()
        );
    }

    my $css = '';
    $css .= $self->thicknessCSS;
    $css .= $self->colorCSS;
    if (defined $self->additionalCSS) {
        $css .= $self->additionalCSS;
    }
    $self->document->additionalStyles($css);

    $self->document->generate();
}

sub generatePageNumberRectangle {
    my ($self) = @_;
    my $cssClass = sprintf('%s rectangle', $self->getLineCSSClass());
    my $rect = My::Printable::Element::Rectangle->new(
        document => $self->document,
        id => 'page-number-rect',
        cssClass => $cssClass,
    );
    my $from_side = $self->modifiers->has('even-page') ? 'left' : 'right';
    my $x_side    = $self->modifiers->has('even-page') ? 'x1'   : 'x2';
    if ($self->unitType eq 'imperial') {
        $rect->$x_side(sprintf('1/4in from %s', $from_side));
        $rect->y2('1/4in from bottom');
        $rect->width('1in');
        $rect->height('3/8in');
    } else {
        $rect->$x_side(sprintf('1/4in from %s', $from_side));
        $rect->y2('6mm from bottom');
        $rect->width('30mm');
        $rect->height('9mm');
    }
    return $rect;
}

sub generateMarginLine {
    my ($self) = @_;
    my $margin_line = My::Printable::Element::Line->new(
        document => $self->document,
        id => 'margin-line',
        cssClass => $self->getMarginLineCSSClass,
    );
    $margin_line->setX($self->getOriginX);
    return $margin_line;
}

sub getUnit {
    my ($self) = @_;

    my $has_denser_grid = grep { $self->modifiers->has($_) }
        qw(5-per-inch denser-grid 1/5in 5mm);

    if ($self->unitType eq 'imperial') {
        if ($has_denser_grid) {
            return '1/5in';
        } else {
            return '1/4in';
        }
    } else {
        if ($has_denser_grid) {
            return '5mm';
        } else {
            return '6mm';
        }
    }
}

###############################################################################

sub getMarginLineCSSClass {
    my ($self) = @_;
    return 'margin-line';
}

sub getDotCSSClass {
    my ($self) = @_;
    return 'dot';
}

sub getLineCSSClass {
    my ($self) = @_;
    return 'line';
}

sub getFeintLineCSSClass {
    my ($self) = @_;
    return 'feint-line';
}

###############################################################################

has 'lineWidthUnit' => (
    is => 'rw',
    default => sub {
        my $unit = My::Printable::Unit->new();
        $unit->defaultUnit('pd');
        return $unit;
    },
    handles => [
        'dpi',
    ],
);

has 'rawLineWidth'       => (is => 'rw');
has 'rawFeintLineWidth'  => (is => 'rw');
has 'rawDotWidth'        => (is => 'rw');
has 'rawMarginLineWidth' => (is => 'rw');

sub lineWidth {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawLineWidth) {
            return $self->computeLineWidth();
        }
        return $self->rawLineWidth;
    }
    my $value = shift;
    $value = $self->lineWidthUnit->pt($value);
    return $self->rawLineWidth($value);
}

sub feintLineWidth {
    my $self = shift;
    if (!scalar @_) {
        if (!$self->rawFeintLineWidth) {
            return $self->computeFeintLineWidth();
        }
        return $self->rawFeintLineWidth;
    }
    my $value = shift;
    $value = $self->lineWidthUnit->pt($value);
    return $self->rawFeintLineWidth($value);
}

sub dotWidth {
    my $self = shift;
    if (!scalar @_) {
        if (!$self->rawDotWidth) {
            return $self->computeDotWidth();
        }
        return $self->rawDotWidth;
    }
    my $value = shift;
    $value = $self->lineWidthUnit->pt($value);
    return $self->rawDotWidth($value);
}

sub marginLineWidth {
    my $self = shift;
    if (!scalar @_) {
        if (!$self->rawMarginLineWidth) {
            return $self->computeMarginLineWidth();
        }
        return $self->rawMarginLineWidth;
    }
    my $value = shift;
    $value = $self->lineWidthUnit->pt($value);
    return $self->rawMarginLineWidth($value);
}

# before thinner-lines, thinner-dots, thinner-grid, denser-grid, and
# other modifiers are applied.

sub baseLineWidth {
    my ($self) = @_;
    return 2 * PD if $self->colorType eq 'black';
    return 8 * PD;
}

sub baseFeintLineWidth {
    my ($self) = @_;
    return 2 / sqrt(2) * PD if $self->colorType eq 'black';
    return 8 / sqrt(2) * PD;
}

sub baseDotWidth {
    my ($self) = @_;
    return 8 * PD if $self->colorType eq 'black';
    return 16 * PD;
}

sub baseMarginLineWidth {
    my ($self) = @_;
    return 2 * PD if $self->colorType eq 'black';
    return 8 * PD;
}

sub computeLineWidth {
    my ($self) = @_;
    my $x = $self->baseLineWidth;
    if ($self->modifiers->has('xx-thinner-lines')) {
        $x /= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thinner-lines')) {
        $x /= 2;
    } elsif ($self->modifiers->has('thinner-lines')) {
        $x /= sqrt(2);
    }
    if ($x < PD) {
        $x = PD;
    }
    return $x;
}

sub computeFeintLineWidth {
    my ($self) = @_;
    my $x = $self->baseFeintLineWidth;
    if ($self->modifiers->has('xx-thinner-lines')) {
        $x /= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thinner-lines')) {
        $x /= 2;
    } elsif ($self->modifiers->has('thinner-lines')) {
        $x /= sqrt(2);
    }
    if ($self->modifiers->has('xx-thinner-grid')) {
        $x /= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thinner-grid')) {
        $x /= 2;
    } elsif ($self->modifiers->has('thinner-grid')) {
        $x /= sqrt(2);
    }
    if ($self->modifiers->has('denser-grid')) {
        $x /= sqrt(2);
    }
    if ($x < PD) {
        $x = PD;
    }
    return $x;
}

sub computeDotWidth {
    my ($self) = @_;
    my $x = $self->baseDotWidth;
    if ($self->modifiers->has('xx-thinner-dots')) {
        $x /= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thinner-dots')) {
        $x /= 2;
    } elsif ($self->modifiers->has('thinner-dots')) {
        $x /= sqrt(2);
    }
    if ($x < PD) {
        $x = PD;
    }
    return $x;
}

sub computeMarginLineWidth {
    my ($self) = @_;
    my $x = $self->baseMarginLineWidth;
    if ($x < PD) {
        $x = PD;
    }
    return $x;
}

###############################################################################

sub getRulingClassName {
    my ($self, $name) = @_;
    my $class_suffix = $name;
    $class_suffix =~ s{(^|[-_]+)
                       ([[:alpha:]])}
                      {uc $2}gex;
    my $ruling_class_name = "My::Printable::Ruling::" . $class_suffix;
    return $ruling_class_name;
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
            return '18mm from left';
        } else {
            return '32mm from left';
        }
    }
}

1;
