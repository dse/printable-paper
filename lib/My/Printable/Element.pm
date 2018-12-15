package My::Printable::Element;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;
use Class::Thingy::Delegate;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(round3);

use List::Util qw(min max);
use Storable qw(dclone);

public "id";

public "x1", set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public "x2", set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public "y1", set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};
public "y2", set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

public "xPointSeries";
public "yPointSeries";

public "origXPointSeries";
public "origYPointSeries";

public "spacing", set => sub {
    my ($self, $value) = @_;
    return $self->pt($value);
};
public "spacingX", set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public "spacingY", set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

public "cssClass";
public "cssStyle";

public "originX", set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public "originY", set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

public "document";              # My::Printable::Document

public "extendLeft";
public "extendRight";
public "extendTop";
public "extendBottom";

# mainly for grids
public 'dotHeight', default => 0, set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public 'dotWidth', default => 0, set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

delegate "unit",        via => "document";
delegate "unitX",       via => "document";
delegate "unitY",       via => "document";

delegate "svgDocument", via => "document";
delegate "svgRoot",     via => "document";
delegate 'svgDefs',     via => 'document';

use constant USE_SVG_PATTERNS => 0;

public "svgLayer", lazy_default => sub {
    my ($self) = @_;
    my $id = $self->id;
    die("id not defined before node called\n") if !defined $id;
    my $doc = $self->svgDocument;
    my $g = $doc->createElement("g");
    $g->setAttribute("id", $id);
    $self->document->appendSVGLayer($g);
    return $g;
}, delete => "deleteSVGLayer";

# MAKE FASTER
sub createSVGLine {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $doc->createElement('line');

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $cssStyle = $args{cssStyle} // $self->cssStyle;
    $cssStyle = $self->document->doubleCurly($cssStyle);

    $line->setAttribute('x1', sprintf('%.3f', $args{x1} // $args{x}));
    $line->setAttribute('x2', sprintf('%.3f', $args{x2} // $args{x}));
    $line->setAttribute('y1', sprintf('%.3f', $args{y1} // $args{y}));
    $line->setAttribute('y2', sprintf('%.3f', $args{y2} // $args{y}));
    $line->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    $line->setAttribute('style', $cssStyle) if defined $cssStyle && $cssStyle ne '';
    return $line;
}

sub createSVGDot {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $doc->createElement('line');

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $cssStyle = $args{cssStyle} // $self->cssStyle;
    $cssStyle = $self->document->doubleCurly($cssStyle);

    my $x = sprintf('%.3f', $args{x});
    my $y = sprintf('%.3f', $args{y});
    $line->setAttribute('x1', $x);
    $line->setAttribute('x2', $x);
    $line->setAttribute('y1', $y);
    $line->setAttribute('y2', $y);
    $line->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    $line->setAttribute('style', $cssStyle) if defined $cssStyle && $cssStyle ne '';
    return $line;
}

sub createSVGRectangle {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $rectangle = $doc->createElement('rect');

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $cssStyle = $args{cssStyle} // $self->cssStyle;
    $cssStyle = $self->document->doubleCurly($cssStyle);

    $rectangle->setAttribute('x', sprintf('%.3f', $args{x}));
    $rectangle->setAttribute('y', sprintf('%.3f', $args{y}));
    $rectangle->setAttribute('width',  sprintf('%.3f', $args{width}));
    $rectangle->setAttribute('height', sprintf('%.3f', $args{height}));
    $rectangle->setAttribute('rx', sprintf('%.3f', $args{rx})) if $args{rx};
    $rectangle->setAttribute('ry', sprintf('%.3f', $args{ry})) if $args{ry};
    $rectangle->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
    $rectangle->setAttribute('style', $cssStyle) if defined $cssStyle && $cssStyle ne '';
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
    my $originX = $self->originX // $self->document->originX;

    $self->xPointSeries(My::Printable::PointSeries->new(
        spacing => $spacingX,
        min     => scalar($self->x1 // $self->document->leftMarginX),
        max     => scalar($self->x2 // $self->document->rightMarginX),
        origin  => $originX,
    ));
    $self->origXPointSeries(My::Printable::PointSeries->new(
        spacing => $spacingX,
        min     => scalar($self->document->leftMarginX),
        max     => scalar($self->document->rightMarginX),
        origin  => $originX,
    ));
}

sub computeY {
    my ($self) = @_;

    my $spacingY = $self->spacingY // $self->spacing // $self->ptY("1unit");
    my $originY = $self->originY // $self->document->originY;

    $self->yPointSeries(My::Printable::PointSeries->new(
        spacing => $spacingY,
        min     => scalar($self->y1 // $self->document->topMarginY),
        max     => scalar($self->y2 // $self->document->bottomMarginY),
        origin  => $originY,
    ));
    $self->origYPointSeries(My::Printable::PointSeries->new(
        spacing => $spacingY,
        min     => scalar($self->document->topMarginY),
        max     => scalar($self->document->bottomMarginY),
        origin  => $originY,
    ));
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

public 'patternCounter', default => 0;
sub getPatternCounter {
    my ($self) = @_;
    return $self->patternCounter($self->patternCounter + 1);
}

# MAKE FASTER
sub drawDotPattern {
    my ($self, %args) = @_;

    my $cssClass = $args{cssClass} // $self->cssClass;
    my $cssStyle = $args{cssStyle} // $self->cssStyle;
    $cssStyle = $self->document->doubleCurly($cssStyle);

    my $xPointSeries = $args{xPointSeries} // $self->xPointSeries;
    my $yPointSeries = $args{yPointSeries} // $self->yPointSeries;

    if (USE_SVG_PATTERNS) {
        # THIS CODE MAY NOT WORK ANYMORE.
        # IT DOES NOT YET ACCOUNT FOR DOTHEIGHT OR DOTWIDTH.
        my $pattern = $self->svgDocument->createElement('pattern');

        my $x1 = $xPointSeries->startPoint;
        my $x2 = $xPointSeries->endPoint;
        my $y1 = $yPointSeries->startPoint;
        my $y2 = $yPointSeries->endPoint;

        my $type = $args{type} // "dots";

        my $x = $xPointSeries->startPoint;
        my $y = $yPointSeries->startPoint;

        if (defined $xPointSeries && defined $yPointSeries) {
            my $pattern_id = sprintf('%s-pattern-%d-%s',
                                     $self->id,
                                     $self->getPatternCounter,
                                     $type);
            my $pattern = $self->svgDocument->createElement('pattern');
            my $viewBox = sprintf('0 0 %.3f %.3f',
                                  $xPointSeries->spacing,
                                  $yPointSeries->spacing);
            $pattern->setAttribute('id', $pattern_id);
            $pattern->setAttribute('x', $x - $xPointSeries->spacing / 2);
            $pattern->setAttribute('y', $y - $yPointSeries->spacing / 2);
            $pattern->setAttribute('width', $xPointSeries->spacing);
            $pattern->setAttribute('height', $yPointSeries->spacing);
            $pattern->setAttribute('patternUnits', 'userSpaceOnUse');
            $pattern->setAttribute('viewBox', $viewBox);

            my $line = $self->createSVGLine(x => $xPointSeries->spacing / 2,
                                            y => $yPointSeries->spacing / 2,
                                            cssClass => $cssClass,
                                            cssStyle => $cssStyle);
            $pattern->appendChild($line);

            $self->svgDefs->appendChild($pattern);

            my $rect = $self->svgDocument->createElement('rect');
            $rect->setAttribute('x', $x1 - $xPointSeries->spacing / 2);
            $rect->setAttribute('y', $y1 - $yPointSeries->spacing / 2);
            $rect->setAttribute('width',  ($x2 - $x1) + ($xPointSeries->spacing));
            $rect->setAttribute('height', ($y2 - $y1) + ($yPointSeries->spacing));
            $rect->setAttribute('fill', sprintf('url(#%s)', $pattern_id));
            $self->svgLayer->appendChild($rect);
        }
    } else {
        my $dw2 = $self->dotWidth / 2;
        my $dh2 = $self->dotHeight / 2;
        my @x = $xPointSeries->getPoints();
        my @y = $yPointSeries->getPoints();
        my $layer = $self->svgLayer;
        foreach my $x (@x) {
            foreach my $y (@y) {
                if ($dw2 && $dh2) {
                    my $ellipse = $self->document->svgDocument->createElement('circle');
                    $ellipse->setAttribute('cx', $x);
                    $ellipse->setAttribute('cy', $y);
                    $ellipse->setAttribute('rx', $dw2);
                    $ellipse->setAttribute('ry', $dh2);
                    $ellipse->setAttribute('class', $cssClass) if defined $cssClass && $cssClass ne '';
                    $ellipse->setAttribute('style', $cssStyle) if defined $cssStyle && $cssStyle ne '';
                    $layer->appendChild($ellipse);
                } else {
                    my %a;
                    my $line;
                    if ($dw2) {
                        my $x1 = $x - $dw2;
                        my $x2 = $x + $dw2;
                        $a{x1} = $x1;
                        $a{x2} = $x2;
                        $a{y} = $y;
                        $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                        $a{cssStyle} = $cssStyle if defined $cssStyle && $cssStyle ne '';
                        $line = $self->createSVGLine(%a);
                    } elsif ($dh2) {
                        my $y1 = $y - $dh2;
                        my $y2 = $y + $dh2;
                        $a{y1} = $y1;
                        $a{y2} = $y2;
                        $a{x} = $x;
                        $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                        $a{cssStyle} = $cssStyle if defined $cssStyle && $cssStyle ne '';
                        $line = $self->createSVGLine(%a);
                    } else {
                        $a{y} = $y;
                        $a{x} = $x;
                        $a{cssClass} = $cssClass if defined $cssClass && $cssClass ne '';
                        $a{cssStyle} = $cssStyle if defined $cssStyle && $cssStyle ne '';
                        $line = $self->createSVGDot(%a);
                    }
                    $layer->appendChild($line);
                }
            }
        }
    }
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

    if (USE_SVG_PATTERNS) {
        my $direction = $args{direction};
        my $pattern = $self->svgDocument->createElement('pattern');
        my $cssClass = $args{cssClass};
        my $cssStyle = $args{cssStyle};
        my $xPointSeries = $args{xPointSeries};
        my $yPointSeries = $args{yPointSeries};
        my $x1 = $args{x1} // $xPointSeries->startPoint;
        my $x2 = $args{x2} // $xPointSeries->endPoint;
        my $y1 = $args{y1} // $yPointSeries->startPoint;
        my $y2 = $args{y2} // $yPointSeries->endPoint;
        my $spacing;

        my $type = $args{type} // sprintf("%s-lines", $direction);

        my $pattern_id = sprintf('%s-pattern-%d-%s',
                                 $self->id,
                                 $self->getPatternCounter,
                                 $type);
        my $viewBox;
        my $fudge = 18;
        my $line;
        my $rect;

        if ($direction eq "horizontal") {
            $spacing = $yPointSeries->spacing;
            $viewBox = sprintf('0 0 %.3f %.3f',
                               ($x2 - $x1 + $fudge * 2),
                               $spacing);
            $line = $self->createSVGLine(
                y => $spacing / 2,
                x1 => $fudge,
                x2 => $fudge + $x2 - $x1,
                cssClass => $cssClass,
                cssStyle => $cssStyle,
            );
            $pattern->setAttribute('x', $x1 - $fudge);
            $pattern->setAttribute('y', $yPointSeries->startPoint - $spacing / 2);
            $pattern->setAttribute('width', $x2 - $x1 + $fudge * 2);
            $pattern->setAttribute('height', $spacing);

            $rect = $self->svgDocument->createElement('rect');
            $rect->setAttribute('x', $x1 - $fudge);
            $rect->setAttribute('y', $y1 - $spacing / 2);
            $rect->setAttribute('width', $x2 - $x1 + $fudge * 2);
            $rect->setAttribute('height', $y2 - $y1 + $spacing);
        } elsif ($direction eq "vertical") {
            $spacing = $xPointSeries->spacing;
            $viewBox = sprintf('0 0 %.3f %.3f',
                               $spacing,
                               ($y2 - $y1 + $fudge * 2));
            $line = $self->createSVGLine(
                x => $spacing / 2,
                y1 => $fudge,
                y2 => $fudge + $y2 - $y1,
                cssClass => $cssClass,
                cssStyle => $cssStyle,
            );
            $pattern->setAttribute('x', $xPointSeries->startPoint - $spacing / 2);
            $pattern->setAttribute('y', $y1 - $fudge);
            $pattern->setAttribute('width', $spacing);
            $pattern->setAttribute('height', $y2 - $y1 + $fudge * 2);

            $rect = $self->svgDocument->createElement('rect');
            $rect->setAttribute('x', $x1 - $spacing / 2);
            $rect->setAttribute('y', $y1 - $fudge);
            $rect->setAttribute('width', $x2 - $x1 + $spacing);
            $rect->setAttribute('height', $y2 - $y1 + $fudge * 2);
        }
        $pattern->setAttribute('id', $pattern_id);
        $pattern->setAttribute('patternUnits', 'userSpaceOnUse');
        $pattern->setAttribute('viewBox', $viewBox);
        $pattern->appendChild($line);
        $self->svgDefs->appendChild($pattern);

        $rect->setAttribute('fill', sprintf('url(#%s)', $pattern_id));
        $self->svgLayer->appendChild($rect);
    } else {
        my $direction = $args{direction};
        my $cssClass = $args{cssClass};
        my $cssStyle = $args{cssStyle};
        my $xPointSeries = $args{xPointSeries};
        my $yPointSeries = $args{yPointSeries};
        my $x1 = $args{x1} // $xPointSeries->startPoint;
        my $x2 = $args{x2} // $xPointSeries->endPoint;
        my $y1 = $args{y1} // $yPointSeries->startPoint;
        my $y2 = $args{y2} // $yPointSeries->endPoint;
        my $spacing;
        if ($direction eq "horizontal") {
            my @y = $yPointSeries->getPoints();
            foreach my $y (@y) {
                my $line = $self->createSVGLine(
                    x1 => $x1, x2 => $x2, y => $y,
                    cssClass => $cssClass,
                    cssStyle => $cssStyle,
                );
                $self->svgLayer->appendChild($line);
            }
        } elsif ($direction eq "vertical") {
            my @x = $xPointSeries->getPoints();
            foreach my $x (@x) {
                my $line = $self->createSVGLine(
                    y1 => $y1, y2 => $y2, x => $x,
                    cssClass => $cssClass,
                    cssStyle => $cssStyle,
                );
                $self->svgLayer->appendChild($line);
            }
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
