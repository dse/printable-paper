package My::Printable::Paper::Element;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:const :trigger strokeDashArray strokeDashOffset);

use List::Util qw(min max any);
use Storable qw(dclone);
use Data::Dumper qw(Dumper);
use Text::Trim qw(trim);
use Scalar::Util qw(blessed);

use Moo;

has id => (is => 'rw');

has x1 => (is => 'rw', trigger => triggerUnitX('x1'));
has x2 => (is => 'rw', trigger => triggerUnitX('x2'));
has y1 => (is => 'rw', trigger => triggerUnitY('y1'));
has y2 => (is => 'rw', trigger => triggerUnitY('y2'));

has xPointSeries => (is => 'rw');
has yPointSeries => (is => 'rw');
has origXPointSeries => (is => 'rw');
has origYPointSeries => (is => 'rw');

has canShiftPointsX => (is => 'rw', default => 0);
has canShiftPointsY => (is => 'rw', default => 0);
has canShiftPoints  => (is => 'rw', default => 0);

has spacing  => (is => 'rw', trigger => triggerUnit('spacing'));
has spacingX => (is => 'rw', trigger => triggerUnitX('spacingX'));
has spacingY => (is => 'rw', trigger => triggerUnitY('spacingY'));

has cssClass => (is => 'rw');
has lineCap => (is => 'rw', default => 'round'); # butt, round, or square

has originX => (is => 'rw', trigger => triggerUnitX('originX'));
has originY => (is => 'rw', trigger => triggerUnitY('originY'));

has document => (
    is => 'rw',
    handles => [
        "unit",
        "unitX",
        "unitY",
        "svgDocument",
        "svgRoot",
        'svgDefs',
        'getElements',
        'getElement',
    ],
);                              # My::Printable::Paper::Document

has extendLeft => (is => 'rw');
has extendRight => (is => 'rw');
has extendTop => (is => 'rw');
has extendBottom => (is => 'rw');

# mainly for grids
has dotDashWidth  => (is => 'rw', default => 0, trigger => triggerUnitX('dotDashWidth'));
has dotDashHeight => (is => 'rw', default => 0, trigger => triggerUnitY('dotDashHeight'));

has dotDashStartAtBottom => (is => 'rw', default => 0);
has dotDashStartAtTop    => (is => 'rw', default => 0);
has dotDashStartAtLeft   => (is => 'rw', default => 0);
has dotDashStartAtRight  => (is => 'rw', default => 0);

has svgLayer => (
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

has rawExcludePointsFrom => (
    is => 'rw',
    default => sub { return []; },
);

sub excludePointsFrom {
    my $self = shift;
    if (scalar @_) {
        my @elements = $self->getElements(@_);
        return $self->rawExcludePointsFrom(\@elements);
    } else {
        return $self->rawExcludePointsFrom();
    }
}

sub BUILD {
    my ($self) = @_;
    foreach my $method (qw(x1 x2 y1 y2
                           spacing spacingX spacingY
                           originX originY dotDashWidth dotDashHeight)) {
        $self->$method($self->$method) if defined $self->$method;
    }
}

sub includesX {
    my ($self, $x) = @_;
    my $ps = $self->xPointSeries;
    return 0 if !$ps;
    return $ps->includes($x) && !$self->excludesX($x);
}

sub includesY {
    my ($self, $y) = @_;
    my $ps = $self->yPointSeries;
    return 0 if !$ps;
    return $ps->includes($y) && !$self->excludesY($y);
}

sub excludesX {
    my ($self, $x) = @_;
    my $exclude = $self->excludePointsFrom;
    return 0 if !$exclude;
    return any { $_->includesX($x) } @$exclude;
}

sub excludesY {
    my ($self, $y) = @_;
    my $exclude = $self->excludePointsFrom;
    return 0 if !$exclude;
    return any { $_->includesY($y) } @$exclude;
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

    my $canShiftPoints = $self->canShiftPointsX || $self->canShiftPoints;

    my $leftClip   = $self->document->leftClip   // 0;
    my $rightClip  = $self->document->rightClip  // 0;
    if ($leftClip  < 0) { $leftClip  = 0; }
    if ($rightClip < 0) { $rightClip = 0; }

    $self->xPointSeries(My::Printable::Paper::PointSeries->new(
        axis                => 'x',
        paperDimension      => $self->document->width,
        spacing             => $spacingX,
        min                 => scalar($self->x1 // $self->document->leftMarginX),
        max                 => scalar($self->x2 // $self->document->rightMarginX),
        origin              => $originX,
        canShiftPoints      => $canShiftPoints,
        startVisibleBoundary => $leftClip,
        endVisibleBoundary  => ($self->document->width - $rightClip),
    ));
    $self->origXPointSeries(My::Printable::Paper::PointSeries->new(
        axis                => 'x',
        paperDimension      => $self->document->width,
        spacing             => $spacingX,
        min                 => scalar($self->document->leftMarginX),
        max                 => scalar($self->document->rightMarginX),
        origin              => $originX,
        canShiftPoints      => $canShiftPoints,
        startVisibleBoundary => $leftClip,
        endVisibleBoundary  => ($self->document->width - $rightClip),
    ));

    $self->originX($self->xPointSeries->origin);
}

sub computeY {
    my ($self) = @_;

    my $spacingY = $self->spacingY // $self->spacing // $self->ptY("1unit");
    my $originY = $self->originY // $self->document->originY;

    my $canShiftPoints = $self->canShiftPointsY || $self->canShiftPoints;

    my $topClip    = $self->document->topClip    // 0;
    my $bottomClip = $self->document->bottomClip // 0;
    if ($topClip    < 0) { $topClip    = 0; }
    if ($bottomClip < 0) { $bottomClip = 0; }

    $self->yPointSeries(My::Printable::Paper::PointSeries->new(
        axis                 => 'y',
        paperDimension       => $self->document->height,
        spacing              => $spacingY,
        min                  => scalar($self->y1 // $self->document->topMarginY),
        max                  => scalar($self->y2 // $self->document->bottomMarginY),
        origin               => $originY,
        canShiftPoints       => $canShiftPoints,
        startVisibleBoundary => $topClip,
        endVisibleBoundary   => ($self->document->height - $bottomClip),
    ));
    $self->origYPointSeries(My::Printable::Paper::PointSeries->new(
        axis                 => 'y',
        paperDimension       => $self->document->height,
        spacing              => $spacingY,
        min                  => scalar($self->document->topMarginY),
        max                  => scalar($self->document->bottomMarginY),
        origin               => $originY,
        canShiftPoints       => $canShiftPoints,
        startVisibleBoundary => $topClip,
        endVisibleBoundary   => ($self->document->height - $bottomClip),
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

sub drawDotPatternUsingSVGDottedLines {
    my ($self, %args) = @_;

    my $dotsX = $args{dotsX} // 1;
    my $dotsY = $args{dotsY} // 1;

    my $dw = $self->dotDashWidth;
    my $dh = $self->dotDashHeight;
    if ($dw && $dh) {
        # dotted lines won't achieve what we want.
        return $self->drawDotPatternUsingDots(%args);
    }
    if (scalar @{$self->excludePointsFrom}) {
        # dotted lines won't exclude points
        return $self->drawDotPatternUsingDots(%args);
    }

    my $cssClass     = $args{cssClass} // $self->cssClass;

    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;
    my $dw2 = $dw / 2;
    my $dh2 = $dh / 2;
    my $layer = $self->svgLayer;

    if ($dotsX != 1 && $dotsY != 1) {
        $self->drawDotPatternUsingSVGDottedHorizontalLines(%args);
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    } elsif ($dotsX != 1 && $dh) {
        $self->drawDotPatternUsingSVGDottedHorizontalLines(%args);
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    } elsif ($dotsY != 1 && $dw) {
        $self->drawDotPatternUsingSVGDottedHorizontalLines(%args);
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    } elsif ($dotsX != 1) {
        $self->drawDotPatternUsingSVGDottedHorizontalLines(%args);
    } elsif ($dotsY != 1) {
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    } elsif ($dw) {
        $self->drawDotPatternUsingSVGDottedHorizontalLines(%args);
    } elsif ($dh) {
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    } else {
        # pick an arbitrary one
        $self->drawDotPatternUsingSVGDottedVerticalLines(%args);
    }
}

sub drawDotPatternUsingSVGDottedHorizontalLines {
    my ($self, %args) = @_;

    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;
    my $cssClass     = $args{cssClass} // $self->cssClass;
    my $layer = $self->svgLayer;
    my $dw = $self->dotDashWidth;
    my $dh = $self->dotDashHeight;

    my $x1 = $xPointSeries->startPoint;
    my $x2 = $xPointSeries->endPoint;
    $x1 -= $dw / 2;
    $x2 += $dw / 2;

    my $spacing = $xPointSeries->spacing / ($args{dotsX} // 1);

    # series of horizontal dotted lines
    my %dash = (
        min => $x1,
        max => $x2,
        center => $xPointSeries->startPoint,
        length => $dw,
        spacing => $spacing,
    );
    my $dasharray = strokeDashArray(%dash);
    my $dashoffset = strokeDashOffset(%dash);
    foreach my $y ($yPointSeries->getPoints()) {
        next if $self->excludesY($y);
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
}

sub drawDotPatternUsingSVGDottedVerticalLines {
    my ($self, %args) = @_;

    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;
    my $cssClass     = $args{cssClass} // $self->cssClass;
    my $layer = $self->svgLayer;
    my $dw = $self->dotDashWidth;
    my $dh = $self->dotDashHeight;

    my $y1 = $yPointSeries->startPoint;
    my $y2 = $yPointSeries->endPoint;
    $y1 -= $dh / 2;
    $y2 += $dh / 2;

    my $spacing = $yPointSeries->spacing / ($args{dotsY} // 1);

    # series of vertical dotted lines
    my %dash = (
        min => $y1,
        max => $y2,
        center => $yPointSeries->startPoint,
        length => $dh,
        spacing => $spacing,
    );
    my $dasharray = strokeDashArray(%dash);
    my $dashoffset = strokeDashOffset(%dash);
    foreach my $x ($xPointSeries->getPoints()) {
        next if $self->excludesX($x);
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

sub drawDotPatternUsingHorizontalRowsOfDots {
    my ($self, %args) = @_;

    my $dotsX = (delete $args{dotsX}) // 1;
    my $dotsY = (delete $args{dotsY}) // 1;

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $xPointSeries = (delete $args{xPointSeries}) // $self->xPointSeries;
    my $yPointSeries = (delete $args{yPointSeries}) // $self->yPointSeries;

    $xPointSeries = $xPointSeries->clone();
    $xPointSeries->spacing($xPointSeries->spacing / $dotsX);

    $self->drawDotPatternUsingDots(
        %args,
        xPointSeries => $xPointSeries,
        yPointSeries => $yPointSeries,
    );
}

sub drawDotPatternUsingVerticalColumnsOfDots {
    my ($self, %args) = @_;

    my $dotsX = (delete $args{dotsX}) // 1;
    my $dotsY = (delete $args{dotsY}) // 1;
    $dotsX //= 1;
    $dotsY //= 1;

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $xPointSeries = (delete $args{xPointSeries}) // $self->xPointSeries;
    my $yPointSeries = (delete $args{yPointSeries}) // $self->yPointSeries;

    $yPointSeries = $yPointSeries->clone();
    $yPointSeries->spacing($yPointSeries->spacing / $dotsY);

    $self->drawDotPatternUsingDots(
        %args,
        xPointSeries => $xPointSeries,
        yPointSeries => $yPointSeries,
    );
}

# MAKE FASTER
sub drawDotPatternUsingDots {
    my ($self, %args) = @_;

    my $dotsX = $args{dotsX} // 1;
    my $dotsY = $args{dotsY} // 1;

    if ($dotsX != 1 || $dotsY != 1) {
        $self->drawDotPatternUsingHorizontalRowsOfDots(%args);
        $self->drawDotPatternUsingVerticalColumnsOfDots(%args);
        return;
    }

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;

    if ($dotsX != 1) {
        $xPointSeries = $xPointSeries->clone();
        $xPointSeries->spacing($xPointSeries->spacing / $dotsX);
    }
    if ($dotsY != 1) {
        $yPointSeries = $yPointSeries->clone();
        $yPointSeries->spacing($yPointSeries->spacing / $dotsY);
    }

    my $dw2 = $self->dotDashWidth / 2;
    my $dh2 = $self->dotDashHeight / 2;
    my @x = $xPointSeries->getPoints();
    my @y = $yPointSeries->getPoints();
    my $layer = $self->svgLayer;
  xValue:
    foreach my $x (@x) {
        next xValue if $self->excludesX($x);
      yValue:
        foreach my $y (@y) {
            next yValue if $self->excludesY($y);
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
            next if $self->excludesY($y);
            my %line = (
                x1 => $x1, x2 => $x2, y => $y,
                cssClass => $cssClass,
            );
            $line{attr} = $args{attr} if defined $args{attr};
            my $line = $self->createSVGLine(%line);
            $self->svgLayer->appendChild($line);
        }
    } elsif ($direction eq "vertical") {
        $cssClass = trim(($cssClass // '') . ' vertical');
        my @x = $xPointSeries->getPoints();
        foreach my $x (@x) {
            next if $self->excludesX($x);
            my %line = (
                y1 => $y1, y2 => $y2, x => $x,
                cssClass => $cssClass,
            );
            $line{attr} = $args{attr} if defined $args{attr};
            my $line = $self->createSVGLine(%line);
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
