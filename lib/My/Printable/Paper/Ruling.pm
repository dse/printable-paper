package My::Printable::Paper::Ruling;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Document;
use My::Printable::Paper::Element::Rectangle;
use My::Printable::Paper::Unit qw(:const);
use My::Printable::Paper::Color qw(:const);
use My::Printable::Paper::Util qw(side_direction snapcmp);
use My::Printable::Paper::Element::Line;

use Moo;

has 'document' => (
    is => 'rw',
    default => sub {
        return My::Printable::Paper::Document->new();
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
        'isA6SizeClass',
        'ptX',
        'ptY',
        'pt',
        'originX',
        'originY',
        'dryRun',
        'verbose',
        'generatePS',
        'generatePDF',
        'generate2Up',
        'generate4Up',
        'generate2Page',
        'generate2Page2Up',
        'generate2Page4Up',
    ],
);

use constant rulingName => 'none';
use constant hasLineGrid => 0;
use constant hasPageNumberRectangle => 0;

use Text::Trim qw(trim);
use Data::Dumper;

sub thicknessCSS {
    my ($self) = @_;

    my $lw  = $self->lineWidth;
    my $mjw = $self->majorLineWidth;
    my $fw  = $self->feintLineWidth;
    my $dw  = $self->dotWidth;
    my $mw  = $self->marginLineWidth;

    my $lo  = 1;
    my $mjo = 1;
    my $fo  = 1;
    my $do  = 1;
    my $mo  = 1;

    if ($lw  < PD) { $lo  = $lw  / PD; $lw  = PD; }
    if ($mjw < PD) { $mjo = $mjw / PD; $mjw = PD; }
    if ($fw  < PD) { $fo  = $fw  / PD; $fw  = PD; }
    if ($dw  < PD) { $do  = $dw  / PD; $dw  = PD; }
    if ($mw  < PD) { $mo  = $mw  / PD; $mw  = PD; }

    return <<"EOF";
        .line        { stroke-width: {{  ${lw} pt }}; opacity:  ${lo}; }
        .major-line  { stroke-width: {{ ${mjw} pt }}; opacity: ${mjo}; }
        .feint-line  { stroke-width: {{  ${fw} pt }}; opacity:  ${fo}; }
        .dot         { stroke-width: {{  ${dw} pt }}; opacity:  ${do}; }
        .margin-line { stroke-width: {{  ${mw} pt }}; opacity:  ${mo}; }
EOF
}

has 'rawLineColor'       => (is => 'rw');
has 'rawMajorLineColor'  => (is => 'rw');
has 'rawFeintLineColor'  => (is => 'rw');
has 'rawDotColor'        => (is => 'rw');
has 'rawMarginLineColor' => (is => 'rw');

sub defaultLineColor {
    my ($self) = @_;
    return COLOR_BLUE if $self->colorType eq 'color';
    return COLOR_GRAY if $self->colorType eq 'grayscale';
    return COLOR_BLACK;
}
sub defaultMajorLineColor {
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
        My::Printable::Paper::Color->new($value)
    )->asHex;
}

sub majorLineColor {
    my $self = shift;
    if (!scalar @_) {
        if (!defined $self->rawMajorLineColor) {
            return $self->defaultMajorLineColor;
        }
        return $self->rawMajorLineColor->asHex;
    }
    my $value = shift;
    return $self->rawMajorLineColor(
        My::Printable::Paper::Color->new($value)
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
        My::Printable::Paper::Color->new($value)
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
        My::Printable::Paper::Color->new($value)
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
        My::Printable::Paper::Color->new($value)
    )->asHex;
}

sub colorCSS {
    my ($self) = @_;

    my $lineColor       = $self->lineColor;
    my $majorLineColor  = $self->majorLineColor;
    my $feintLineColor  = $self->feintLineColor;
    my $dotColor        = $self->dotColor;
    my $marginLineColor = $self->marginLineColor;

    return <<"EOF";
        .line        { stroke: $lineColor; }
        .major-line  { stroke: $majorLineColor; }
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

    my $unit = $self->getUnit();
    $self->document->setUnit($unit) if defined $unit;

    my $originX = $self->getOriginX();
    $self->document->originX($originX) if defined $originX;

    my $originY = $self->getOriginY();
    $self->document->originY($originY) if defined $originY;

    $self->generateRuling();

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

# *around* which to define subclass methods
sub generateRuling {
    my ($self) = @_;
}

sub generatePageNumberRectangle {
    my ($self) = @_;
    my $cssClass = sprintf('%s rectangle', $self->getLineCSSClass());
    my $rect = My::Printable::Paper::Element::Rectangle->new(
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

sub getUnit {
    my ($self) = @_;

    if ($self->modifiers->has('unit')) {
        my $unit = $self->modifiers->get('unit');
        if (defined $unit) {
            return $unit;
        }
    }

    my $hasDenserGrid = grep { $self->modifiers->has($_) }
        qw(5-per-inch denser-grid 1/5in 5mm);

    if ($self->unitType eq 'imperial') {
        if ($hasDenserGrid) {
            return '1/5in';
        } else {
            return '1/4in';
        }
    } else {
        if ($hasDenserGrid) {
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

sub getMajorLineCSSClass {
    my ($self) = @_;
    return 'major-line';
}

###############################################################################

has 'lineWidthUnit' => (
    is => 'rw',
    default => sub {
        my $unit = My::Printable::Paper::Unit->new();
        $unit->defaultUnit('pd');
        return $unit;
    },
    handles => [
        'dpi',
    ],
);

has 'rawLineWidth'       => (is => 'rw');
has 'rawMajorLineWidth'  => (is => 'rw');
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

sub majorLineWidth {
    my $self = shift;
    if (!scalar @_) {
        if (!$self->rawMajorLineWidth) {
            return $self->computeMajorLineWidth();
        }
        return $self->rawMajorLineWidth;
    }
    my $value = shift;
    $value = $self->lineWidthUnit->pt($value);
    return $self->rawMajorLineWidth($value);
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

sub baseMajorLineWidth {
    my ($self) = @_;
    return  4 / sqrt(2) * PD if $self->colorType eq 'black';
    return 16 / sqrt(2) * PD;
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

sub computeMajorLineWidth {
    my ($self) = @_;
    my $x = $self->baseMajorLineWidth;
    if ($self->modifiers->has('xx-thinner-lines')) {
        $x /= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thinner-lines')) {
        $x /= 2;
    } elsif ($self->modifiers->has('thinner-lines')) {
        $x /= sqrt(2);
    }
    if ($self->modifiers->has('xx-thicker-major-lines')) {
        $x *= (2 * sqrt(2));
    } elsif ($self->modifiers->has('x-thicker-major-lines')) {
        $x *= 2;
    } elsif ($self->modifiers->has('thicker-major-lines')) {
        $x *= sqrt(2);
    }
    if ($self->modifiers->has('denser-grid')) {
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
    my $ruling_class_name = "My::Printable::Paper::Ruling::" . $class_suffix;
    return $ruling_class_name;
}

sub getOriginX {
    my ($self, $side) = @_;
    $side //= 'left';
    my $value;
    if ($self->modifiers->has('left-margin-line') || $self->modifiers->has('margin-line')) {
        $value = $self->modifiers->get('left-margin-line') // $self->modifiers->get('margin-line');
    } elsif ($self->modifiers->has('right-margin-line')) {
        $value = $self->modifiers->get('right-margin-line');
    }
    if (defined $value && $value eq 'yes') {
        $value = $self->getDefaultMarginLineX($side);
    }
    return $value;
}

sub getOriginY {
    my ($self, $side) = @_;
    $side //= 'top';
    my $value;
    if ($self->modifiers->has('top-margin-line')) {
        $value = $self->modifiers->get('top-margin-line');
    } elsif ($self->modifiers->has('bottom-margin-line')) {
        $value = $self->modifiers->get('bottom-margin-line');
    }
    if (defined $value && $value eq 'yes') {
        $value = $self->getDefaultMarginLineY($side);
    }
    return;
}

sub getDefaultMarginLineY {
    my ($self, $side) = @_;
    $side //= 'top';
    if ($self->unitType eq 'imperial') {
        return '0.5in from ' . $side;
    } else {
        return '12mm from ' . $side;
    }
}

sub getDefaultMarginLineX {
    my ($self, $side) = @_;
    $side //= 'left';
    if ($self->unitType eq 'imperial') {
        if ($self->isA6SizeClass()) {
            return '0.5in from ' . $side;
        } elsif ($self->isA5SizeClass()) {
            return '0.75in from ' . $side;
        } else {
            return '1.25in from ' . $side;
        }
    } else {
        if ($self->isA6SizeClass()) {
            return '12mm from ' . $side;
        } elsif ($self->isA5SizeClass()) {
            return '18mm from ' . $side;
        } else {
            return '32mm from ' . $side;
        }
    }
}

###############################################################################

sub hasMarginLine {
    my ($self, $side) = @_;
    $side //= 'left';
    my $direction = side_direction($side);
    die("margin line side must be left, right, top, or bottom\n") unless defined $direction;

    return $self->modifiers->has('left-margin-line') || $self->modifiers->has('margin-line') if $side eq 'left';
    return $self->modifiers->has('right-margin-line')                                        if $side eq 'right';
    return $self->modifiers->has('top-margin-line')                                          if $side eq 'top';
    return $self->modifiers->has('bottom-margin-line')                                       if $side eq 'bottom';
    return;
}

sub getMarginLinePosition {
    my ($self, $side) = @_;
    $side //= 'left';
    my $direction = side_direction($side);
    die("margin line side must be left, right, top, or bottom\n") unless defined $direction;

    my $marginLinePosition;
    if ($direction eq 'vertical') {
        if ($side eq 'left') {
            $marginLinePosition = $self->modifiers->get('left-margin-line') // $self->modifiers->get('margin-line');
        } else {
            $marginLinePosition = $self->modifiers->get('right-margin-line');
        }
        if (!defined $marginLinePosition) {
            my $originX = $self->ptX($self->getOriginX($side));
            my $halfX   = $self->ptX('50%');
            my $originXIsLeftOrCenter = snapcmp($originX, $halfX) <= 0;
            my $isOppositeSide = 0;
            if ($side eq 'left') {
                if ($originXIsLeftOrCenter) {
                    $marginLinePosition = $originX;
                } else {
                    $marginLinePosition = $self->width - $originX;
                    $isOppositeSide = 1;
                }
            } else {
                if ($originXIsLeftOrCenter) {
                    $marginLinePosition = $self->width - $originX;
                } else {
                    $marginLinePosition = $originX;
                    $isOppositeSide = 1;
                }
            }
            if ($isOppositeSide) {
                # eh?
            }
        }
    } else {
        if ($side eq 'top') {
            $marginLinePosition = $self->modifiers->get('top-margin-line');
        } else {
            $marginLinePosition = $self->modifiers->get('bottom-margin-line');
        }
        if (!defined $marginLinePosition) {
            my $originY = $self->ptY($self->getOriginY($side));
            my $halfY   = $self->ptY('50%');
            my $originYIsTopOrCenter = snapcmp($originY, $halfY) <= 0;
            my $isOppositeSide = 0;
            if ($side eq 'top') {
                if ($originYIsTopOrCenter) {
                    $marginLinePosition = $originY;
                } else {
                    $marginLinePosition = $self->height - $originY;
                    $isOppositeSide = 1;
                }
            } else {
                if ($originYIsTopOrCenter) {
                    $marginLinePosition = $self->height - $originY;
                    $isOppositeSide = 1;
                } else {
                    $marginLinePosition = $originY;
                }
            }
            if ($isOppositeSide) {
                # eh?
            }
        }
    }
    return $marginLinePosition;
}

sub generateMarginLine {
    my ($self, $side) = @_;
    $side //= 'left';
    my $direction = side_direction($side);
    die("margin line side must be left, right, top, or bottom\n") unless defined $direction;

    my $cssClass = trim(($self->getMarginLineCSSClass // '') . ' ' . $direction);
    my $margin_line = My::Printable::Paper::Element::Line->new(
        document => $self->document,
        id => 'margin-line',
        cssClass => $cssClass,
    );
    if ($direction eq 'vertical') {
        $margin_line->setX($self->getMarginLinePosition($side));
        return $margin_line;
    } else {                    # horizontal
        $margin_line->setY($self->getMarginLinePosition($side));
        return $margin_line;
    }
}

###############################################################################

1;
