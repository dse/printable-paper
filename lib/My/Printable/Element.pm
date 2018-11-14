package My::Printable::Element;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;
use Class::Thingy::Delegate;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(get_point_series round3);

use List::Util qw(min max);

public "id";

public "x1";
public "x2";
public "y1";
public "y2";

public "xValues";
public "yValues";

public "origXValues";
public "origYValues";

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

public "svgLayer", lazy_default => sub {
    my ($self) = @_;
    my $id = $self->id;
    die("id not defined before node called\n") if !defined $id;
    my $doc = $self->svgDocument;
    my $g = $doc->createElement("g");
    $g->setAttribute("id", $id);
    return $g;
};

sub createLine {
    my ($self, %args) = @_;
    my $doc = $self->document->svgDocument;
    my $line = $self->document->svgDocument->createElement('line');
    $line->setAttribute('x1', round3($args{x1} // $args{x}));
    $line->setAttribute('x2', round3($args{x2} // $args{x}));
    $line->setAttribute('y1', round3($args{y1} // $args{y}));
    $line->setAttribute('y2', round3($args{y2} // $args{y}));
    $line->setAttribute('class', $args{cssClass}) if defined $args{cssClass};
    return $line;
}

sub appendLine {
    my $self = shift;
    my $line;
    if (scalar @_ == 1) {
        $line = shift;
        if (ref $line && $line->isa('XML::LibXML::Element')) {
            # do nothing
        } else {
            die("Bad call to appendLine");
        }
    } elsif ((scalar @_) % 2 == 0) {
        $line = $self->createLine(@_);
    } else {
        die("Bad call to appendLine");
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

sub setBottomY {
    my ($self, $value) = @_;
    $self->bottomY($self->ptY($value));
}

sub setTopY {
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
    my @xValues = get_point_series(
        spacing => scalar($self->spacingX // $self->spacing // $self->ptX("1unit")),
        min     => scalar($self->leftX // $self->leftMarginX),
        max     => scalar($self->rightX // $self->rightMarginX),
        origin  => scalar($self->originX // ($self->width / 2)),
    );
    $self->xValues([@xValues]);
    $self->origXValues([@xValues]);
}

sub computeY {
    my ($self) = @_;
    my @yValues = get_point_series(
        spacing => scalar($self->spacingY // $self->spacing // $self->ptY("1unit")),
        min     => scalar($self->bottomY // $self->bottomMarginY),
        max     => scalar($self->topY    // $self->topMarginY),
        origin  => scalar($self->originY // ($self->height / 2)),
    );
    $self->yValues([@yValues]);
    $self->origYValues([@yValues]);
}

sub snap {
    my ($self, $id) = @_;
    $self->snapX($id);
    $self->snapY($id);
}

sub snapX {
    my ($self) = @_;
    my $xValues = $self->xValues;
    if (defined $xValues) {
        # TODO
    }
    my $origXValues = $self->origXValues;
    if (defined $origXValues) {
        # TODO
    }
}

sub snapY {
    my ($self) = @_;
    my $yValues = $self->yValues;
    if (defined $yValues) {
        # TODO
    }
    my $origYValues = $self->origYValues;
    if (defined $origYValues) {
        # TODO
    }
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
    my $xValues = $self->xValues;
    return unless defined $xValues;

    my $x = max(@$xValues);
    for (my $i = 1; $i <= $number; $i += 1) {
        $x += $self->spacingX;
        push(@$xValues, $x);
    }

    # TODO: also, origXValues
}

sub extendLeftBy {
    my ($self, $number) = @_;
    my $xValues = $self->xValues;
    return unless defined $xValues;

    my $x = min(@$xValues);
    for (my $i = 1; $i <= $number; $i += 1) {
        $x -= $self->spacingX;
        unshift(@$xValues, $x);
    }

    # TODO: also, origXValues
}

sub extendBottomBy {
    my ($self, $number) = @_;
    my $yValues = $self->yValues;
    return unless defined $yValues;

    my $y = min(@$yValues);
    for (my $i = 1; $i <= $number; $i += 1) {
        $y -= $self->spacingY;
        unshift(@$yValues, $y);
    }

    # TODO: also, origYValues
}

sub extendTopBy {
    my ($self, $number) = @_;
    my $yValues = $self->yValues;
    return unless defined $yValues;

    my $y = max(@$yValues);
    for (my $i = 1; $i <= $number; $i += 1) {
        $y += $self->spacingY;
        push(@$yValues, $y);
    }

    # TODO: also, origYValues
}

sub chop {
    my ($self) = @_;
    $self->chopX();
    $self->chopY();
}

sub chopX {
    my ($self) = @_;
    my $xValues = $self->xValues;
    return unless defined $xValues;

    # float
    @$xValues = grep { $_ >= $self->leftX  } @$xValues if defined $self->leftX;
    @$xValues = grep { $_ <= $self->rightX } @$xValues if defined $self->rightX;
}

sub chopY {
    my ($self) = @_;
    my $yValues = $self->yValues;
    return unless defined $yValues;

    # float
    @$yValues = grep { $_ >= $self->bottomY } @$yValues if defined $self->bottomY;
    @$yValues = grep { $_ <= $self->topY    } @$yValues if defined $self->topY;
}

sub exclude {
    my ($self, @id) = @_;
    $self->excludeX(@id);
    $self->excludeY(@id);
}

sub excludeX {
    my ($self, @id) = @_;
    my $xValues = $self->xValues;
    return unless defined $xValues;

    # float
    @$xValues = grep { $_ >= $self->leftMarginX  } @$xValues if defined $self->leftMarginX;
    @$xValues = grep { $_ <= $self->rightMarginX } @$xValues if defined $self->rightMarginX;

    foreach my $id (@id) {
        my $element = $self->elements->{$id};
        next unless $element;

        # TODO
    }
}

sub excludeY {
    my ($self, @id) = @_;
    my $yValues = $self->yValues;
    return unless defined $yValues;

    # float
    @$yValues = grep { $_ >= $self->bottomMarginY } @$yValues if defined $self->bottomMarginY;
    @$yValues = grep { $_ <= $self->topMarginY    } @$yValues if defined $self->topMarginY;

    foreach my $id (@id) {
        my $element = $self->elements->{$id};
        next unless $element;

        # TODO
    }
}

1;
