package My::Printable::Ruling;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Document;
use My::Printable::Element::Rectangle;

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
    ],
);

use constant rulingName => 'none';
use constant hasLineGrid => 0;
use constant lineGridThinness => 0;
use constant lineThinness => 0;
use constant dotThinness => 0;
use constant hasMarginLine => 0;
use constant hasPageNumberRectangle => 0;

use Text::Trim qw(trim);

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

sub getMarginLineThicknessCSSClassList {
    my ($self) = @_;
    if ($self->colorType eq 'black') {
        return ('stroke-3');
    } else {
        return ();
    }
}

sub getMarginLineColorCSSClassList {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return ('gray');
    } elsif ($self->colorType eq 'color') {
        return ('red');
    } else {
        return ('black');
    }
}

sub getMarginLineTypeCSSClassList {
    my ($self) = @_;
    return ('line');
}

sub getDotThicknessCSSClassList {
    my ($self) = @_;
}

sub getDotColorCSSClassList {
    my ($self) = @_;
}

sub getDotTypeCSSClassList {
    my ($self) = @_;
    return ('dot');
}

sub getLineThicknessCSSClassList {
    my ($self) = @_;
}

sub getLineColorCSSClassList {
    my ($self) = @_;
}

sub getLineTypeCSSClassList {
    my ($self) = @_;
    return ('line');
}

sub getFeintLineThicknessCSSClassList {
    my ($self) = @_;
}

sub getFeintLineColorCSSClassList {
    my ($self) = @_;
}

sub getFeintLineTypeCSSClassList {
    my ($self) = @_;
    return ('line');
}

###############################################################################

sub getMarginLineCSSClass {
    my ($self) = @_;

    if ($self->colorType eq 'grayscale') {
        return 'gray margin line';
    } elsif ($self->colorType eq 'color') {
        return 'red margin line';
    } else {
        return 'stroke-3 black line';
    }
}

sub getLineCSSClass {
    my ($self) = @_;

    my $thinness =
        $self->modifiers->has('x-thinner-lines') ? 2 :
        $self->modifiers->has('thinner-lines') ? 1 :
        0;                            # 0 to 2
    $thinness += $self->lineThinness; # 0 to 4

    my $thinness_class_A = [
        '',                     # regular
        'thin',
        'x-thin',
        'xx-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-3 black',
        'stroke-2 black',
        'stroke-1 black',
        'stroke-1 black stroke-half',
        'stroke-1 black stroke-quarter',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return trim("$thinness_class_A gray line");
    } elsif ($self->colorType eq 'color') {
        return trim("$thinness_class_A blue line");
    } else {
        return trim("$thinness_class_B line");
    }

    # regular for anode
    # thin/x-thin/xx-thin for line-dot-grid
    # x-thin for quadrille
    # regular for seyes
}

sub getFeintLineCSSClass {
    my ($self) = @_;

    my $thinness;
    if ($self->hasLineGrid) {
        $thinness =
            $self->modifiers->has('x-thinner-grid') ? 2 :
            $self->modifiers->has('thinner-grid') ? 1 :
            0;                  # 0 to 2
        $thinness +=
            $self->modifiers->has('denser-grid') ? 1 :
            0;                  # 0 to 3
        $thinness += $self->lineGridThinness; # 0 to 4
    } else {
        $thinness =
            $self->modifiers->has('x-thinner-lines') ? 2 :
            $self->modifiers->has('thinner-lines') ? 1 :
            0;                  # 0 to 2
        $thinness += $self->lineThinness; # 0 to 5
    }

    my $thinness_class_A = [
        'thin',
        'x-thin',
        'xx-thin',
        'xx-thin',
        'xx-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-1 black',
        'stroke-1 black stroke-half',
        'stroke-1 black stroke-quarter',
        'stroke-1 black stroke-quarter',
        'stroke-1 black stroke-quarter',
        'stroke-1 black stroke-quarter',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return trim("$thinness_class_A gray line");
    } elsif ($self->colorType eq 'color') {
        return trim("$thinness_class_A blue line");
    } else {
        return trim("$thinness_class_B line");
    }
}

sub getDotCSSClass {
    my ($self) = @_;

    my $thinness =
        $self->modifiers->has('x-thinner-dots') ? 2 :
        $self->modifiers->has('thinner-dots') ? 1 :
        0;                           # 0 to 2
    $thinness += $self->dotThinness; # -1 to 4
    $thinness += 1;                  # 0 to 5

    my $thinness_class_A = [
        'semi-thick',
        '',                     # regular
        'semi-thin',
        'thin',
        'x-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-7 black',
        'stroke-5 black',
        'stroke-4 black',
        'stroke-3 black',
        'stroke-2 black',
        'stroke-1 black',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return trim("$thinness_class_A gray dot");
    } elsif ($self->colorType eq 'color') {
        return trim("$thinness_class_A blue dot");
    } else {
        return trim("$thinness_class_B dot");
    }

    # regular for dot-grid
    # thin for line-dot-graph
    # semi-thick/regular/semi-thin for line-dot-grid
}

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
