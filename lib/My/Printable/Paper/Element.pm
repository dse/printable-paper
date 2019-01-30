package My::Printable::Paper::Element;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:const :around);

use List::Util qw(min max);
use Storable qw(dclone);
use Data::Dumper qw(Dumper);
use Text::Trim qw(trim);

use Moo;

has 'id' => (is => 'rw');

has 'x1' => (is => 'rw');
has 'x2' => (is => 'rw');
has 'y1' => (is => 'rw');
has 'y2' => (is => 'rw');

around 'x1' => \&aroundUnitX;
around 'x2' => \&aroundUnitX;
around 'y1' => \&aroundUnitY;
around 'y2' => \&aroundUnitY;

has 'xPointSeries' => (is => 'rw');
has 'yPointSeries' => (is => 'rw');
has 'origXPointSeries' => (is => 'rw');
has 'origYPointSeries' => (is => 'rw');

has 'shiftPointsX' => (is => 'rw', default => 0);
has 'shiftPointsY' => (is => 'rw', default => 0);
has 'shiftPoints'  => (is => 'rw', default => 0);

has 'spacing' => (is => 'rw');
has 'spacingX' => (is => 'rw');
has 'spacingY' => (is => 'rw');

around 'spacing' => \&aroundUnit;
around 'spacingX' => \&aroundUnitX;
around 'spacingY' => \&aroundUnitY;

has "cssClass" => (is => 'rw');

has 'originX' => (is => 'rw');
has 'originY' => (is => 'rw');

around 'originX' => \&aroundUnitX;
around 'originY' => \&aroundUnitY;

has "document" => (
    is => 'rw',
    handles => [
        "unit",
        "unitX",
        "unitY",
        "svgDocument",
        "svgRoot",
        'svgDefs',
    ],
);                              # My::Printable::Paper::Document

has "extendLeft" => (is => 'rw');
has "extendRight" => (is => 'rw');
has "extendTop" => (is => 'rw');
has "extendBottom" => (is => 'rw');

# mainly for grids
has 'dotDashWidth'  => (is => 'rw', default => 0);
has 'dotDashHeight' => (is => 'rw', default => 0);

has 'dotDashStartAtBottom' => (is => 'rw', default => 0);
has 'dotDashStartAtTop'    => (is => 'rw', default => 0);
has 'dotDashStartAtLeft'   => (is => 'rw', default => 0);
has 'dotDashStartAtRight'  => (is => 'rw', default => 0);

around 'dotDashWidth'  => \&aroundUnitX;
around 'dotDashHeight' => \&aroundUnitY;

has "svgLayer" => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $id = $self->id;
        if (!defined $id) {
            die("id not defined on $self before svgLayer called");
        }
        my $doc = $self->svgDocument;
        my $g = $doc->createElement("g");
        $g->setAttribute("id", $id);
        $self->document->appendSVGLayer($g);
        return $g;
    },
    clearer => "deleteSVGLayer",
);

sub BUILD {
    my ($self) = @_;
    foreach my $method (qw(x1 x2 y1 y2
                           spacing spacingX spacingY
                           originX originY dotDashWidth dotDashHeight)) {
        $self->$method($self->$method) if defined $self->$method;
    }
}

# MAKE FASTER
sub createSVGLine {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $doc->createElement('line');

    my $cssClass = $args{cssClass} // $self->cssClass;

    $line->setAttribute('x1', sprintf('%.3f', $args{x1} // $args{x}));
    $line->setAttribute('x2', sprintf('%.3f', $args{x2} // $args{x}));
    $line->setAttribute('y1', sprintf('%.3f', $args{y1} // $args{y}));
    $line->setAttribute('y2', sprintf('%.3f', $args{y2} // $args{y}));
    $line->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    if ($args{attr}) {
        foreach my $name (sort keys %{$args{attr}}) {
            $line->setAttribute($name, $args{attr}->{$name});
        }
    }
    return $line;
}

# MAKE FASTER?
sub createSVGDot {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $doc->createElement('line');

    my $cssClass = $args{cssClass} // $self->cssClass;

    my $x = sprintf('%.3f', $args{x});
    my $y = sprintf('%.3f', $args{y});
    $line->setAttribute('x1', $x);
    $line->setAttribute('x2', $x);
    $line->setAttribute('y1', $y);
    $line->setAttribute('y2', $y);
    $line->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    if ($args{attr}) {
        foreach my $name (sort keys %{$args{attr}}) {
            $line->setAttribute($name, $args{attr}->{$name});
        }
    }
    return $line;
}

sub createSVGRectangle {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $rectangle = $doc->createElement('rect');

    my $cssClass = $args{cssClass} // $self->cssClass;

    $rectangle->setAttribute('x', sprintf('%.3f', $args{x}));
    $rectangle->setAttribute('y', sprintf('%.3f', $args{y}));
    $rectangle->setAttribute('width',  sprintf('%.3f', $args{width}));
    $rectangle->setAttribute('height', sprintf('%.3f', $args{height}));
    $rectangle->setAttribute('rx', sprintf('%.3f', $args{rx})) if $args{rx};
    $rectangle->setAttribute('ry', sprintf('%.3f', $args{ry})) if $args{ry};
    $rectangle->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    if ($args{attr}) {
        foreach my $name (sort keys %{$args{attr}}) {
            $rectangle->setAttribute($name, $args{attr}->{$name});
        }
    }
    return $rectangle;
}

sub appendSVGElement {
    my $self = shift;
    my $svg_element;
    if (scalar @_ == 1) {
        $svg_element = shift;
        if (ref $svg_element && $svg_element->isa('XML::LibXML::Element')) {
            # do nothing
        } else {
            die("Bad call to appendSVGElement");
        }
    } elsif ((scalar @_) % 2 == 0) {
        $svg_element = $self->createSVGLine(@_);
    } else {
        die("Bad call to appendSVGElement");
    }
    $self->svgLayer->appendChild($svg_element);
}

sub ptX {
    my ($self, $value) = @_;
    return $self->unitX->pt($value);
}

sub ptY {
    my ($self, $value) = @_;
    return $self->unitY->pt($value);
}

sub pt {
    my ($self, $value) = @_;
    return $self->unit->pt($value);
}

sub setX1 {
    my ($self, $value) = @_;
    $self->x1($self->ptX($value));
}

sub setX2 {
    my ($self, $value) = @_;
    $self->x2($self->ptX($value));
}

sub setY1 {
    my ($self, $value) = @_;
    $self->y1($self->ptY($value));
}

sub setY2 {
    my ($self, $value) = @_;
    $self->y2($self->ptY($value));
}

sub setX {
    my ($self, $value) = @_;
    $self->setX1($value);
    $self->setX2($value);
}

sub setY {
    my ($self, $value) = @_;
    $self->setY1($value);
    $self->setY2($value);
}

sub setSpacingX {
    my ($self, $value) = @_;
    $self->spacingX($self->ptX($value));
}

sub setSpacingY {
    my ($self, $value) = @_;
    $self->spacingY($self->ptY($value));
}

sub setSpacing {
    my ($self, $value) = @_;
    $self->spacingX($self->ptX($value));
    $self->spacingY($self->ptY($value));
}

###############################################################################

sub compute {
    my ($self) = @_;
    $self->computeX();
    $self->computeY();
}

sub computeX {
    my ($self) = @_;

    my $spacingX = $self->spacingX // $self->spacing // $self->ptX("1unit");
    my $originX  = $self->originX // $self->document->originX;

    my $shiftPoints = $self->shiftPointsX || $self->shiftPoints;

    $self->xPointSeries(My::Printable::Paper::PointSeries->new(
        spacing     => $spacingX,
        min         => scalar($self->x1 // $self->document->leftMarginX),
        max         => scalar($self->x2 // $self->document->rightMarginX),
        origin      => $originX,
        shiftPoints => $shiftPoints,
    ));
    $self->origXPointSeries(My::Printable::Paper::PointSeries->new(
        spacing     => $spacingX,
        min         => scalar($self->document->leftMarginX),
        max         => scalar($self->document->rightMarginX),
        origin      => $originX,
        shiftPoints => $shiftPoints,
    ));

    $self->originX($self->xPointSeries->origin);
}

sub computeY {
    my ($self) = @_;

    my $spacingY = $self->spacingY // $self->spacing // $self->ptY("1unit");
    my $originY = $self->originY // $self->document->originY;

    my $shiftPoints = $self->shiftPointsY || $self->shiftPoints;

    $self->yPointSeries(My::Printable::Paper::PointSeries->new(
        spacing     => $spacingY,
        min         => scalar($self->y1 // $self->document->topMarginY),
        max         => scalar($self->y2 // $self->document->bottomMarginY),
        origin      => $originY,
        shiftPoints => $shiftPoints,
    ));
    $self->origYPointSeries(My::Printable::Paper::PointSeries->new(
        spacing     => $spacingY,
        min         => scalar($self->document->topMarginY),
        max         => scalar($self->document->bottomMarginY),
        origin      => $originY,
        shiftPoints => $shiftPoints,
    ));

    $self->originY($self->yPointSeries->origin);
}

sub snap {
    my ($self, $id) = @_;
    $self->snapX($id);
    $self->snapY($id);
}

sub snapX {
    my ($self) = @_;
    # TODO
}

sub snapY {
    my ($self) = @_;
    # TODO
}

sub extend {
    my ($self) = @_;
    my $left   = $self->extendLeft;
    my $right  = $self->extendRight;
    my $top    = $self->extendTop;
    my $bottom = $self->extendBottom;
    $self->extendLeftBy($left)     if defined $left;
    $self->extendRightBy($right)   if defined $right;
    $self->extendTopBy($top)       if defined $top;
    $self->extendBottomBy($bottom) if defined $bottom;
}

sub extendRightBy {
    my ($self, $number) = @_;

    $self->xPointSeries->extendAhead($number);
}

sub extendLeftBy {
    my ($self, $number) = @_;

    $self->xPointSeries->extendBehind($number);
}

sub extendBottomBy {
    my ($self, $number) = @_;

    $self->yPointSeries->extendAhead($number);
}

sub extendTopBy {
    my ($self, $number) = @_;

    $self->yPointSeries->extendBehind($number);
}

sub chop {
    my ($self) = @_;
    $self->chopX();
    $self->chopY();
}

sub chopX {
    my ($self) = @_;

    $self->xPointSeries->chopBehind($self->document->leftMarginX);
    $self->xPointSeries->chopAhead($self->document->rightMarginX);
}

sub chopY {
    my ($self) = @_;

    $self->yPointSeries->chopBehind($self->document->topMarginY);
    $self->yPointSeries->chopAhead($self->document->bottomMarginY);
}

# another netscape pdf rendering bug workaround
use constant DOTTED_LINE_FUDGE_FACTOR => 0.01;

sub drawDotPatternUsingSVGDottedLines {
    my ($self, %args) = @_;

    my $dw = $self->dotDashWidth;
    my $dh = $self->dotDashHeight;
    if ($dw && $dh) {
        # dotted lines won't achieve what we want.
        return $self->drawDotPatternUsingDots(%args);
    }

    my $cssClass     = $args{cssClass} // $self->cssClass;

    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;
    my $dw2 = $dw / 2;
    my $dh2 = $dw / 2;
    my $layer = $self->svgLayer;

    if ($dw) {
        # series of horizontal dotted lines
        my $dasharray = sprintf('%.3f %.3f',
                                DOTTED_LINE_FUDGE_FACTOR + $dw,
                                $xPointSeries->spacing - $dw - DOTTED_LINE_FUDGE_FACTOR);
        my $dashoffset = sprintf('%.3f', DOTTED_LINE_FUDGE_FACTOR / 2);
        my $x1 = $xPointSeries->startPoint - $dw / 2;
        my $x2 = $xPointSeries->endPoint   + $dw / 2;
        if ($self->dotDashStartAtLeft) {
            $x1 += $dw / 2;
            $x2 += $dw / 2;
        }
        if ($self->dotDashStartAtRight) {
            $x1 -= $dw / 2;
            $x2 -= $dw / 2;
        }
        foreach my $y ($yPointSeries->getPoints()) {
            my %a = (
                x1 => $x1,
                x2 => $x2,
                y => $y,
                attr => {
                    'stroke-dasharray' => $dasharray,
                    'stroke-dashoffset' => $dashoffset,
                },
            );
            $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
            my $line = $self->createSVGLine(%a);
            $layer->appendChild($line);
        }
    } else {
        # series of vertical dotted lines
        my $dasharray = sprintf('%.3f %.3f',
                                DOTTED_LINE_FUDGE_FACTOR + $dh,
                                $yPointSeries->spacing - $dh - DOTTED_LINE_FUDGE_FACTOR);
        my $dashoffset = sprintf('%.3f', DOTTED_LINE_FUDGE_FACTOR / 2);
        my $y1 = $yPointSeries->startPoint - $dh / 2;
        my $y2 = $yPointSeries->endPoint   + $dh / 2;
        if ($self->dotDashStartAtTop) {
            $y1 += $dh / 2;
            $y2 += $dh / 2;
        }
        if ($self->dotDashStartAtBottom) {
            $y1 -= $dh / 2;
            $y2 -= $dh / 2;
        }
        foreach my $x ($xPointSeries->getPoints()) {
            my %a = (
                y1 => $y1,
                y2 => $y2,
                x => $x,
                attr => {
                    'stroke-dasharray' => $dasharray,
                    'stroke-dashoffset' => $dashoffset,
                },
            );
            $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
            my $line = $self->createSVGLine(%a);
            $layer->appendChild($line);
        }
    }
}

sub drawDotPatternUsingSVGPatterns {
    my ($self, %args) = @_;

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;

    my $dw2 = $self->dotDashWidth / 2;
    my $dh2 = $self->dotDashHeight / 2;

    my $layer = $self->svgLayer;

    my $patternId = $self->id . '-pattern';
    my $pattern = $self->document->svgDocument->createElement('pattern');
    my $patternWidth  = $xPointSeries->spacing;
    my $patternHeight = $yPointSeries->spacing;
    my $patternViewBox = sprintf('0 0 %.3f %.3f', $patternWidth, $patternHeight);
    my $translateX = $xPointSeries->startPoint - $patternWidth / 2;
    my $translateY = $yPointSeries->startPoint - $patternHeight / 2;

    $pattern->setAttribute('id', $patternId);
    $pattern->setAttribute('x', '0');
    $pattern->setAttribute('y', '0');
    $pattern->setAttribute('width', sprintf('%.3f', $patternWidth));
    $pattern->setAttribute('height', sprintf('%.3f', $patternHeight));
    $pattern->setAttribute('viewBox', $patternViewBox);
    $pattern->setAttribute('patternUnits', 'userSpaceOnUse');
    $pattern->setAttribute('patternTransform', sprintf('translate(%.3f, %.3f)', $translateX, $translateY));

    if ($dw2 && $dh2) {
        my $ellipse = $self->document->svgDocument->createElement('circle');
        $ellipse->setAttribute('cx', sprintf('%.3f', $patternWidth / 2));
        $ellipse->setAttribute('cy', sprintf('%.3f', $patternHeight / 2));
        $ellipse->setAttribute('rx', $dw2);
        $ellipse->setAttribute('ry', $dh2);
        $ellipse->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
        $pattern->appendChild($ellipse);
    } else {
        my %a;
        if ($dw2) {
            $a{x1} = $patternWidth / 2 - $dw2;
            $a{x2} = $patternWidth / 2 + $dw2;
            $a{y} = $patternHeight / 2;
        } elsif ($dh2) {
            $a{y1} = $patternHeight / 2 - $dh2;
            $a{y2} = $patternHeight / 2 + $dh2;
            $a{x} = $patternWidth / 2;
        } else {
            $a{x} = $patternWidth / 2;
            $a{y} = $patternHeight / 2;
        }
        $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
        my $line = $self->createSVGLine(%a);
        $pattern->appendChild($line);
    }
    $self->document->svgDefs->appendChild($pattern);

    my $rect = $self->document->svgDocument->createElement('rect');
    my $rectX = $xPointSeries->startPoint - $patternWidth / 2;
    my $rectY = $yPointSeries->startPoint - $patternHeight / 2;
    my $rectWidth  = $xPointSeries->endPoint - $xPointSeries->startPoint + $xPointSeries->spacing;
    my $rectHeight = $yPointSeries->endPoint - $yPointSeries->startPoint + $yPointSeries->spacing;

    $rect->setAttribute('x', sprintf('%.3f', $rectX));
    $rect->setAttribute('y', sprintf('%.3f', $rectY));
    $rect->setAttribute('width', sprintf('%.3f', $rectWidth));
    $rect->setAttribute('height', sprintf('%.3f', $rectHeight));
    my $style = sprintf('stroke: none; fill: url(\'#%s\');', $patternId);
    if (USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND) {
        $style .= ' filter: url(\'#inkscapeBugWorkaroundFilter\');';
    }
    $rect->setAttribute('style', $style);
    $layer->appendChild($rect);
    $self->document->svgInkscapeBugWorkaroundFilter();
}

# MAKE FASTER
sub drawDotPatternUsingDots {
    my ($self, %args) = @_;

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;

    my $dw2 = $self->dotDashWidth / 2;
    my $dh2 = $self->dotDashHeight / 2;
    my @x = $xPointSeries->getPoints();
    my @y = $yPointSeries->getPoints();
    my $layer = $self->svgLayer;
    foreach my $x (@x) {
        foreach my $y (@y) {
            if ($dw2 && $dh2) {
                my $cx = $x;
                my $cy = $y;
                $cx += $dw2 if $self->dotDashStartAtLeft;
                $cx -= $dw2 if $self->dotDashStartAtRight;
                $cy += $dh2 if $self->dotDashStartAtTop;
                $cy -= $dh2 if $self->dotDashStartAtBottom;
                my $ellipse = $self->document->svgDocument->createElement('circle');
                $ellipse->setAttribute('cx', sprintf('%.3f', $cx));
                $ellipse->setAttribute('cy', sprintf('%.3f', $cy));
                $ellipse->setAttribute('rx', sprintf('%.3f', $dw2));
                $ellipse->setAttribute('ry', sprintf('%.3f', $dh2));
                $ellipse->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
                $layer->appendChild($ellipse);
            } else {
                my %a;
                my $line;
                if ($dw2) {
                    my $x1 = $x - $dw2;
                    my $x2 = $x + $dw2;
                    if ($self->dotDashStartAtLeft) {
                        $x1 += $dw2;
                        $x2 += $dw2;
                    }
                    if ($self->dotDashStartAtRight) {
                        $x1 -= $dw2;
                        $x2 -= $dw2;
                    }
                    $a{x1} = $x1;
                    $a{x2} = $x2;
                    $a{y} = $y;
                    $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                    $line = $self->createSVGLine(%a);
                } elsif ($dh2) {
                    my $y1 = $y - $dh2;
                    my $y2 = $y + $dh2;
                    if ($self->dotDashStartAtTop) {
                        $y1 += $dh2;
                        $y2 += $dh2;
                    }
                    if ($self->dotDashStartAtBottom) {
                        $y1 -= $dh2;
                        $y2 -= $dh2;
                    }
                    $a{y1} = $y1;
                    $a{y2} = $y2;
                    $a{x} = $x;
                    $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                    $line = $self->createSVGLine(%a);
                } else {
                    $a{y} = $y;
                    $a{x} = $x;
                    $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                    $line = $self->createSVGDot(%a);
                }
                $layer->appendChild($line);
            }
        }
    }
}

sub drawDotPattern {
    my ($self, %args) = @_;
    if (USE_SVG_DOTTED_LINES_FOR_DOT_GRIDS) {
        return $self->drawDotPatternUsingSVGDottedLines(%args);
    }
    if (USE_SVG_PATTERNS_FOR_DOT_GRIDS) {
        return $self->drawDotPatternUsingSVGPatterns(%args);
    }
    return $self->drawDotPatternUsingDots(%args);
}

sub drawHorizontalLinePattern {
    my ($self, %args) = @_;
    $self->drawLinePattern(direction => "horizontal", %args);
}

sub drawVerticalLinePattern {
    my ($self, %args) = @_;
    $self->drawLinePattern(direction => "vertical", %args);
}

sub drawLinePattern {
    my ($self, %args) = @_;

    my $direction = $args{direction};
    my $cssClass = $args{cssClass};
    my $xPointSeries = $args{xPointSeries};
    my $yPointSeries = $args{yPointSeries};
    my $x1 = $args{x1} // $xPointSeries->startPoint;
    my $x2 = $args{x2} // $xPointSeries->endPoint;
    my $y1 = $args{y1} // $yPointSeries->startPoint;
    my $y2 = $args{y2} // $yPointSeries->endPoint;
    my $spacing;
    if ($direction eq "horizontal") {
        $cssClass = trim(($cssClass // '') . ' horizontal');
        my @y = $yPointSeries->getPoints();
        foreach my $y (@y) {
            my $line = $self->createSVGLine(
                x1 => $x1, x2 => $x2, y => $y,
                cssClass => $cssClass,
            );
            $self->svgLayer->appendChild($line);
        }
    } elsif ($direction eq "vertical") {
        $cssClass = trim(($cssClass // '') . ' vertical');
        my @x = $xPointSeries->getPoints();
        foreach my $x (@x) {
            my $line = $self->createSVGLine(
                y1 => $y1, y2 => $y2, x => $x,
                cssClass => $cssClass,
            );
            $self->svgLayer->appendChild($line);
        }
    }
}

sub nearestX {
    my ($self, $value) = @_;
    my $pt = $self->ptX($value);
    return $self->xPointSeries->nearest($pt);
}

sub nearestY {
    my ($self, $value) = @_;
    my $pt = $self->ptY($value);
    return $self->yPointSeries->nearest($pt);
}

1;
