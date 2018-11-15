package My::Printable::Element;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;
use Class::Thingy::Delegate;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(get_series_of_points get_point_series round3);

use List::Util qw(min max);
use Storable qw(dclone);

public "id";

public "x1";
public "x2";
public "y1";
public "y2";

public "xPointSeries";
public "yPointSeries";

public "origXPointSeries";
public "origYPointSeries";

public "spacing";
public "spacingX";
public "spacingY";

public "bottomY";
public "topY";
public "leftX";
public "rightX";

public "cssClass";

public "originX";
public "originY";

public "document";              # My::Printable::Document

public "extendLeft";
public "extendRight";
public "extendTop";
public "extendBottom";

delegate "unitX",         via => "document";
delegate "unitY",         via => "document";
delegate "unit",          via => "document";
delegate "leftMarginX",   via => "document";
delegate "rightMarginX",  via => "document";
delegate "bottomMarginY", via => "document";
delegate "topMarginY",    via => "document";
delegate "width",         via => "document";
delegate "height",        via => "document";
delegate "svgDocument",   via => "document";
delegate "svgRoot",       via => "document";
delegate 'svgDefs',       via => 'document';

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

sub createSVGLine {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $doc->createElement('line');
    $line->setAttribute('x1', round3($args{x1} // $args{x}));
    $line->setAttribute('x2', round3($args{x2} // $args{x}));
    $line->setAttribute('y1', round3($args{y1} // $args{y}));
    $line->setAttribute('y2', round3($args{y2} // $args{y}));
    $line->setAttribute('class', $args{cssClass}) if defined $args{cssClass};
    return $line;
}

sub appendSVGLine {
    my $self = shift;
    my $line;
    if (scalar @_ == 1) {
        $line = shift;
        if (ref $line && $line->isa('XML::LibXML::Element')) {
            # do nothing
        } else {
            die("Bad call to appendSVGLine");
        }
    } elsif ((scalar @_) % 2 == 0) {
        $line = $self->createSVGLine(@_);
    } else {
        die("Bad call to appendSVGLine");
    }
    $self->svgLayer->appendChild($line);
}

sub ptX {
    my ($self, $value) = @_;
    return $self->unitX->pt($value);
}

sub ptY {
    my ($self, $value) = @_;
    return $self->unitY->pt($value);
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

sub setTopY {
    my ($self, $value) = @_;
    $self->bottomY($self->ptY($value));
}

sub setBottomY {
    my ($self, $value) = @_;
    $self->bottomY($self->documentHeight - $self->ptY($value));
}

sub setLeftX {
    my ($self, $value) = @_;
    $self->leftX($self->ptX($value));
}

sub setRightX {
    my ($self, $value) = @_;
    $self->rightX($self->documentWidth - $self->ptX($value));
}

sub setOriginX {
    my ($self, $value) = @_;
    $self->originX($self->ptX($value));
}

sub setOriginY {
    my ($self, $value) = @_;
    $self->originY($self->ptY($value));
}

###############################################################################

sub compute {
    my ($self) = @_;
    $self->computeX();
    $self->computeY();
}

sub computeX {
    my ($self) = @_;

    $self->xPointSeries(My::Printable::PointSeries->new(
        spacing => scalar($self->spacingX // $self->spacing // $self->ptX("1unit")),
        min     => scalar($self->leftX // $self->leftMarginX),
        max     => scalar($self->rightX // $self->rightMarginX),
        origin  => scalar($self->originX // $self->document->originX),
    ));
    $self->origXPointSeries(dclone($self->xPointSeries));
}

sub computeY {
    my ($self) = @_;

    $self->yPointSeries(My::Printable::PointSeries->new(
        spacing => scalar($self->spacingY // $self->spacing // $self->ptY("1unit")),
        min     => scalar($self->topY    // $self->topMarginY),
        max     => scalar($self->bottomY // $self->bottomMarginY),
        origin  => scalar($self->originY // $self->document->originY),
    ));
    $self->origYPointSeries(dclone($self->yPointSeries));
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

    $self->xPointSeries->chopBehind($self->leftX);
    $self->xPointSeries->chopAhead($self->rightX);
}

sub chopY {
    my ($self) = @_;

    $self->yPointSeries->chopBehind($self->topY);
    $self->yPointSeries->chopAhead($self->bottomY);
}

sub chopMargins {
    my ($self) = @_;
    $self->chopMarginsX();
    $self->chopMarginsY();
}

sub chopMarginsX {
    my ($self) = @_;

    $self->xPointSeries->chopBehind($self->leftMarginX);
    $self->xPointSeries->chopAhead($self->rightMarginX);
}

sub chopMarginsY {
    my ($self) = @_;

    $self->yPointSeries->chopBehind($self->topMarginY);
    $self->yPointSeries->chopAhead($self->bottomMarginY);
}

public 'patternCounter', default => 0;
sub getPatternCounter {
    my ($self) = @_;
    return $self->patternCounter($self->patternCounter + 1);
}

sub drawDotPattern {
    my ($self, %args) = @_;
    my $pattern = $self->svgDocument->createElement('pattern');
    my $cssClass = delete $args{cssClass};
    my $xPointSeries = delete $args{xPointSeries};
    my $yPointSeries = delete $args{yPointSeries};

    my $x1 = delete $args{x1};
    my $x2 = delete $args{x2};
    my $y1 = delete $args{y1};
    my $y2 = delete $args{y2};

    my $type = $args{type} // "dots";

    my $x = $xPointSeries->min;
    my $y = $yPointSeries->min;

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
                                        cssClass => $cssClass);
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
    my $pattern = $self->svgDocument->createElement('pattern');
    my $cssClass = $args{cssClass};
    my $xPointSeries = $args{xPointSeries};
    my $yPointSeries = $args{yPointSeries};
    my $x1 = $args{x1} // $xPointSeries->min;
    my $x2 = $args{x2} // $xPointSeries->max;
    my $y1 = $args{y1} // $yPointSeries->min;
    my $y2 = $args{y2} // $yPointSeries->max;
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
        );
        $pattern->setAttribute('x', $x1 - $fudge);
        $pattern->setAttribute('y', $yPointSeries->min - $spacing / 2);
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
        );
        $pattern->setAttribute('x', $xPointSeries->min - $spacing / 2);
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
}

1;
