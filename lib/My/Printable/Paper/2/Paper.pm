package My::Printable::Paper::2::Paper;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::PaperSize;
use My::Printable::Paper::2::LineType;
use My::Printable::Paper::2::PointSeries;
use My::Printable::Paper::2::Coordinate;
use My::Printable::Paper::2::Util qw(:stroke);
use My::Printable::Paper::2::Converter;

use List::Util qw(max any);
use File::Slurp qw(write_file);
use XML::LibXML;
use Sort::Naturally qw(nsort);
use Regexp::Common qw(number);
use Math::Trig qw(:pi);

use Moo;

has id           => (is => 'rw');
has basename     => (is => 'rw');
has originX      => (is => 'rw', default => '50%');
has originY      => (is => 'rw', default => '50%');
has gridSpacingX => (is => 'rw', default => '1/4in');
has gridSpacingY => (is => 'rw', default => '1/4in');
has clipLeft     => (is => 'rw', default => 0);
has clipRight    => (is => 'rw', default => 0);
has clipTop      => (is => 'rw', default => 0);
has clipBottom   => (is => 'rw', default => 0);
has size => (
    is => 'rw',
    default => sub {
        my $self = shift;
        return My::Printable::Paper::2::PaperSize->new(paper => $self);
    },
    handles => [
        'width',
        'height',
        'orientation',
    ],
    trigger => sub {
        state $recurse = 0;
        return if $recurse;
        $recurse += 1;
        my $self = shift;
        sub {
            my $value = $self->size;
            if (eval { $value->isa('My::Printable::Paper::2::PaperSize') }) {
                # do nothing
            } else {
                $self->size(My::Printable::Paper::2::PaperSize->new(
                    $value, paper => $self
                ));
            }
        }->();
        $recurse -= 1;
    },
);
has lineTypeHash    => (is => 'rw', default => sub { return {}; });
has pointSeriesHash => (is => 'rw', default => sub { return {}; });
has dpi             => (is => 'rw', default => 600);

has converter => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        return My::Printable::Paper::2::Converter->new(paper => $self);
    },
);

has svgDocument => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
        return $doc;
    },
);

has svgRootElement => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        my $root = $self->svgDocument->createElement('svg');
        my $width  = $self->xx('width');
        my $height = $self->yy('height');
        my $viewBox = sprintf('%.3f %.3f %.3f %.3f', 0, 0, $width, $height);
        $root->setAttribute('width',  sprintf('%.3fpt', $width));
        $root->setAttribute('height', sprintf('%.3fpt', $height));
        $root->setAttribute('viewBox', $viewBox);
        $root->setAttribute('xmlns', 'http://www.w3.org/2000/svg');
        $self->svgDocument->setDocumentElement($root);
        return $root;
    },
);

has svgDefsElement => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        my $defs = $self->svgDocument->createElement('defs');
        $self->svgRootElement->appendChild($defs);
        return $defs;
    },
);

has svgStyleElement => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        my $style = $self->svgDocument->createElement('style');
        $self->svgRootElement->appendChild($style);
        return $style;
    },
);

has svgTopLevelGroupElement => (
    is => 'rw', lazy => 1, default => sub {
        my $self = shift;
        my $g = $self->svgDocument->createElement('g');
        $g->setAttribute('id', 'top-level-group');
        $self->svgRootElement->appendChild($g);
        return $g;
    },
);

has clipPathElement => (is => 'rw');

sub updateClipPathElement {
    my $self = shift;
    if ($self->clipPathElement) {
        $self->svgDefsElement->removeChild($self->clipPathElement);
        $self->clipPathElement(undef);
    }
    my $width  = $self->xx($self->width);
    my $height = $self->xx($self->height);
    my $clipLeft   = max($self->xx($self->clipLeft), 0);
    my $clipRight  = max($self->xx($self->clipRight), 0);
    my $clipTop    = max($self->yy($self->clipTop), 0);
    my $clipBottom = max($self->yy($self->clipBottom), 0);

    if ($clipLeft > 0 || $clipRight > 0 || $clipTop > 0 || $clipBottom > 0) {
        my $clipX = $clipLeft;
        my $clipY = $clipTop;
        my $clipWidth  = $width  - $clipLeft - $clipRight;
        my $clipHeight = $height - $clipTop  - $clipBottom;

        my $clipPath = $self->svgDocument->createElement('clipPath');
        $clipPath->setAttribute('id', 'document-clip-path');

        my $rect = $self->svgDocument->createElement('rect');
        $rect->setAttribute('x', sprintf('%g', $clipX));
        $rect->setAttribute('y', sprintf('%g', $clipY));
        $rect->setAttribute('width', sprintf('%g', $clipWidth));
        $rect->setAttribute('height', sprintf('%g', $clipHeight));

        $self->svgDefsElement->appendChild($clipPath);
        $clipPath->appendChild($rect);
        $self->clipPathElement($clipPath);

        $self->svgTopLevelGroupElement->setAttribute(
            'clip-path', 'url(#document-clip-path)'
        );
    } else {
        $self->svgTopLevelGroupElement->removeAttribute('clip-path');
    }
}

sub drawGrid {
    my $self = shift;
    my %args = @_;
    my $x = $args{x};           # number, string, or PointSeries
    my $y = $args{y};           # number, string, or PointSeries
    my $lineTypeId = $args{lineTypeId};
    my $lineType = defined $lineTypeId ? $self->lineTypeHash->{$lineTypeId} : undef;
    my $isClosed = $args{isClosed};
    my $parentId = $args{parentId};
    my $id = $args{id};

    my $xIsPointSeries = eval { $x->isa('My::Printable::Paper::2::PointSeries') };
    my $yIsPointSeries = eval { $y->isa('My::Printable::Paper::2::PointSeries') };

    my $spacingX = $xIsPointSeries ? $self->xx($x->step) : $self->xx('gridSpacingX');
    my $spacingY = $yIsPointSeries ? $self->yy($y->step) : $self->yy('gridSpacingY');

    my $group = $self->svgGroupElement(id => $id, parentId => $parentId);

    my %hDashArgs = $lineType->getGridDashArguments(
        axis => 'x',
        coordinates => $x,
        isClosed => $isClosed,
        id => $id,
        parentId => $parentId,
        spacing => $spacingX,
    );

    my %vDashArgs = $lineType->getGridDashArguments(
        axis => 'y',
        coordinates => $y,
        isClosed => $isClosed,
        id => $id,
        parentId => $parentId,
        spacing => $spacingY,
    );

    my @xPt = $self->xx($x);
    my @yPt = $self->yy($y);

    my $x1  = $hDashArgs{point1};
    my $x2  = $hDashArgs{point2};
    my $y1  = $vDashArgs{point1};
    my $y2  = $vDashArgs{point2};

    my $isExtended             = $hDashArgs{isExtended} || $vDashArgs{isExtended};
    my $isExtendedHorizontally = $hDashArgs{isExtended};
    my $isExtendedVertically   = $vDashArgs{isExtended};

    if (!$lineType->isDashedOrDotted) {
        say scalar @xPt;
        say scalar @yPt;
    }

    my $drawVerticalLines = sub {
        foreach my $x (@xPt) {
            $group->appendChild(
                $self->createSVGLine(
                    x => $x, y1 => $y1, y2 => $y2, lineTypeId => $lineTypeId,
                    useStrokeDashCSSClasses => 1,
                    %hDashArgs,
                )
            );
        }
    };

    my $drawHorizontalLines = sub {
        foreach my $y (@yPt) {
            $group->appendChild(
                $self->createSVGLine(
                    y => $y, x1 => $x1, x2 => $x2, lineTypeId => $lineTypeId,
                    useStrokeDashCSSClasses => 1,
                    %vDashArgs,
                )
            );
        }
    };

    # optimization: avoid drawing dot grids twice
    if ($lineType && $lineType->isDotted && $lineType->dots == 1 &&
            !eval { $x->mustExclude } && !eval { $y->mustExclude }) {
        if ($isClosed || !$isExtended) {
            $drawVerticalLines->();
            return;
        }
        if ($isExtendedHorizontally && !$isExtendedVertically) {
            $drawHorizontalLines->();
            return;
        }
        if ($isExtendedVertically && !$isExtendedHorizontally) {
            $drawVerticalLines->();
            return;
        }
    }

    $drawVerticalLines->();
    $drawHorizontalLines->();
}

sub drawHorizontalLines {
    my $self = shift;
    my %args = @_;
    my $y  = $args{y};                      # number, string, or PointSeries
    my $x1 = $args{x1} // '0pt from start'; # number or string
    my $x2 = $args{x2} // '0pt from end';   # number or string
    my $lineTypeId = $args{lineTypeId};
    my $parentId = $args{parentId};
    my $id = $args{id};

    my @yPt  = $self->yy($y);
    my $x1Pt = $self->xx($x1);
    my $x2Pt = $self->xx($x2);

    my $group = $self->svgGroupElement(id => $id, parentId => $parentId);
    foreach my $y (@yPt) {
        $group->appendChild(
            $self->createSVGLine(
                y => $y, x1 => $x1, x2 => $x2, lineTypeId => $lineTypeId,
            )
        );
    }
}

sub drawVerticalLines {
    my $self = shift;
    my %args = @_;
    my $x  = $args{x};                      # number, string, or PointSeries
    my $y1 = $args{y1} // '0pt from start'; # number or string
    my $y2 = $args{y2} // '0pt from end';   # number or string
    my $lineTypeId = $args{lineTypeId};
    my $parentId = $args{parentId};
    my $id = $args{id};

    my @xPt  = $self->xx($x);
    my $y1Pt = $self->yy($y1);
    my $y2Pt = $self->yy($y2);

    my $group = $self->svgGroupElement(id => $id, parentId => $parentId);
    foreach my $x (@xPt) {
        $group->appendChild(
            $self->createSVGLine(
                x => $x, y1 => $y1, y2 => $y2, lineTypeId => $lineTypeId,
            )
        );
    }
}

sub write {
    my $self = shift;
    my %args = @_;
    my $format   = $args{format} // 'pdf'; # pdf, svg, or ps
    my $basename = $self->basename;
    if (!defined $basename) {
        die("write: basename must be specified");
    }
    return $self->writeSVG(%args) if $format eq 'svg';
    return $self->writePDF(%args) if $format eq 'pdf';
    return $self->writePS(%args)  if $format eq 'ps';
}

has 'isGenerated' => (is => 'rw', default => sub { return {}; });

sub getBasePDFFilename {
    my $self = shift;
    return $self->basename . '.pdf';
}

sub getBasePSFilename {
    my $self = shift;
    return $self->basename . '.ps';
}

sub getSVGFilename {
    my $self = shift;
    return $self->basename . '.svg';
}

sub getPDFFilename {
    my $self = shift;
    my ($nUp, $nPages) = $self->nUpNPagesArgs(@_);
    my $filename = $self->basename;
    $filename .= sprintf('-%dup', $nUp)    if $nUp    != 1;
    $filename .= sprintf('-%dpg', $nPages) if $nPages != 1;
    $filename .= '.pdf';
    return $filename;
}

sub getPSFilename {
    my $self = shift;
    my ($nUp, $nPages) = $self->nUpNPagesArgs(@_);
    my $filename = $self->basename;
    $filename .= sprintf('-%dup', $nUp)    if $nUp    != 1;
    $filename .= sprintf('-%dpg', $nPages) if $nPages != 1;
    $filename .= '.ps';
    return $filename;
}

sub writeSVG {
    my $self = shift;
    my %args = @_;
    my $svgFilename = $self->getSVGFilename;
    return if $self->isGenerated->{$svgFilename};
    write_file($svgFilename, $self->toSVG) or die("write $svgFilename: $!\n");
    $self->isGenerated->{$svgFilename} = 1;
}

sub writeBasePDF {
    my $self = shift;
    return if $self->isGenerated->{$self->getBasePDFFilename};
    $self->writeSVG;
    $self->converter->exportSVG(
        $self->getSVGFilename,
        $self->getBasePDFFilename
    );
    $self->isGenerated->{$self->getBasePDFFilename} = 1;
}

sub writeBasePS {
    my $self = shift;
    return if $self->isGenerated->{$self->getBasePSFilename};
    $self->writeSVG;
    $self->converter->exportSVG(
        $self->getSVGFilename,
        $self->getBasePSFilename
    );
    $self->isGenerated->{$self->getBasePSFilename} = 1;
}

sub nUpNPagesArgs {
    my $self = shift;
    my %args;
    my $callingSub = (caller(1))[3];
    $callingSub =~ s{^.*::}{};
    if ((scalar @_) % 2 == 1) {
        die("$callingSub: odd number of arguments passed to nUpNPagesArgs");
    }
    if ($_[0] =~ m{^$RE{num}{int}$} && $_[1] =~ m{^$RE{num}{int}$}) {
        $args{nUp} = shift;
        $args{nPages} = shift;
    }
    %args = (%args, @_);
    return @args{qw(nUp nPages)};
}

sub writePDF {
    my $self = shift;
    my ($nUp, $nPages) = $self->nUpNPagesArgs(@_);
    if (!$nUp) {
        die("writePDF: nUp not specified");
    }
    if (!$nPages) {
        die("writePDF: nPages not specified");
    }
    if ($nUp != 1 && $nUp != 2 && $nUp != 4) {
        die("writePDF: nUp must be 1, 2, or 4");
    }
    if ($nPages != 1 && $nPages != 2) {
        die("writePDF: nPages must be 1 or 2");
    }
    $self->writeBasePDF();
    $self->converter->convertPDF(
        $self->getBasePDFFilename,
        $self->getPDFFilename($nUp, $nPages),
        $nUp, $nPages,
        $self->xx('width'),
        $self->yy('height'),
    );
}

sub writePS {
    my $self = shift;
    my ($nUp, $nPages) = $self->nUpNPagesArgs(@_);
    if (!$nUp) {
        die("writePDF: nUp not specified");
    }
    if (!$nPages) {
        die("writePDF: nPages not specified");
    }
    if ($nUp != 1 && $nUp != 2 && $nUp != 4) {
        die("writePS: nUp must be 1, 2, or 4");
    }
    if ($nPages != 1 && $nPages != 2) {
        die("writePS: nPages must be 1 or 2");
    }
    $self->writeBasePS();
    $self->converter->convertPS(
        $self->getBasePSFilename,
        $self->getPSFilename($nUp, $nPages),
        $nUp, $nPages,
        $self->xx('width'),
        $self->yy('height'),
    );
}

sub pointSeries {
    my $self = shift;
    my %args = @_;
    my $id = $args{id};
    my $pointSeries = My::Printable::Paper::2::PointSeries->new(
        paper => $self,
        %args
    );
    $self->pointSeriesHash->{$id} = $pointSeries if defined $id;
    return $pointSeries;
}

sub addXPointSeries {
    my $self = shift;
    return $self->pointSeries(axis => 'x', @_);
}

sub addYPointSeries {
    my $self = shift;
    return $self->pointSeries(axis => 'y', @_);
}

sub addLineType {
    my $self = shift;
    if (scalar @_ == 1) {
        my $lineType = shift;
        if (eval { $lineType->isa('My::Printable::Paper::2::LineType') }) {
            return $lineType;
        }
        return $self->lineTypeHash->{$lineType}
            if exists $self->lineTypeHash->{$lineType};
        die("no such line type: '$lineType'");
    }
    my %args = @_;
    my $id = $args{id};
    my $lineType = My::Printable::Paper::2::LineType->new(
        paper => $self,
        %args
    );
    $self->lineTypeHash->{$id} = $lineType if defined $id;
    return $lineType;
}

sub startSVG {
    my $self = shift;
    $self->svgDocument();
    $self->svgRootElement();
    $self->svgDefsElement();
    $self->svgStyleElement();
    $self->svgTopLevelGroupElement();
    $self->updateCSS();
    $self->updateClipPathElement();
}

sub endSVG {
    my $self = shift;
    $self->updateCSS();
}

sub updateCSS {
    my $self = shift;
    $self->svgStyleElement->removeChildNodes();
    my $css = $self->getComputedCSS;
    $css =~ s{\s+\z}{};
    $css = "\n" . $css . "\n  ";
    $self->svgStyleElement->appendTextNode($css);
}

sub getComputedCSS {
    my $self = shift;
    my $result = '';
    $result .= <<"END";
        * {
            stroke-linecap: round;
            stroke-linejoin: round;
        }
        *.dashed {
            stroke-linecap: butt;
            stroke-linejoin: butt;
        }
        *.dotted {
            stroke-linecap: round;
            stroke-linejoin: round;
        }
END
    foreach my $lineTypeName (sort keys %{$self->lineTypeHash}) {
        my $lineType = $self->lineTypeHash->{$lineTypeName};
        $result .= $lineType->getComputedCSS;
    }
    foreach my $className (nsort keys %{$self->cssClassValues}) {
        my $hash = $self->cssClassValues->{$className};
        if ($hash && scalar keys %$hash) {
            $result .= <<"END";
        .${className} {
END
            foreach my $property (nsort keys %$hash) {
                my $value = $hash->{$property};
                $result .= <<"END";
            ${property}: ${value};
END
            }
            $result .= <<"END";
        }
END
        }
    }
    return $result;
}

has groupsById => (is => 'rw', default => sub { return {}; });

sub svgGroupElement {
    my $self = shift;
    my %args = @_;
    my $id = $args{id};
    my $hasId = defined $id && $id =~ m{\S};

    if ($hasId) {
        my $group = $self->groupsById->{$id};
        return $group if $group;
    }

    my $parentId = $args{parentId};
    my $hasParentId = defined $parentId && $parentId =~ m{\S};

    my $parent = $hasParentId ? $self->groupsById->{$parentId} :
        $self->svgTopLevelGroupElement;

    my $group = $self->svgDocument->createElement('g');
    $group->setAttribute('id', $id) if $hasId;
    $parent->appendChild($group);

    $self->groupsById->{$id} = $group if $hasId;

    return $group;
}

has cssClassCounters  => (is => 'rw', default => sub { return {}; });
has cssClassesByValue => (is => 'rw', default => sub { return {}; });
has cssClassValues    => (is => 'rw', default => sub { return {}; });

sub getCSSClassNameByValue {
    my ($self, $classNamePrefix, $property, $value) = @_;
    return $self->cssClassesByValue->{$classNamePrefix}->{$property}->{$value}
        if eval { exists $self->cssClassesByValue->{$classNamePrefix}->{$property}->{$value}; };
    my $counter = $self->cssClassCounters->{$classNamePrefix} //= 0;
    $self->cssClassCounters->{$classNamePrefix} += 1;
    my $className = $classNamePrefix . '--' . $counter;
    $self->cssClassesByValue->{$classNamePrefix} //= {};
    $self->cssClassesByValue->{$classNamePrefix}->{$property} //= {};
    $self->cssClassesByValue->{$classNamePrefix}->{$property}->{$value} = $className;
    $self->cssClassValues->{$className} //= {};
    $self->cssClassValues->{$className}->{$property} = $value;
    return $className;
}

sub getStrokeDashArrayClassName {
    my ($self, $value) = @_;
    return undef if !defined $value;
    return $self->getCSSClassNameByValue('sda', 'stroke-dasharray', $value);
}

sub getStrokeDashOffsetClassName {
    my ($self, $value) = @_;
    return undef if !defined $value;
    return $self->getCSSClassNameByValue('sdo', 'stroke-dashoffset', $value);
}

sub drawCircle {
    my ($self, %args) = @_;
    my $group = $self->svgGroupElement(%args);
    $group->appendChild($self->createSVGCircle(%args));
}

sub drawLine {
    my ($self, %args) = @_;
    my $group = $self->svgGroupElement(%args);
    $group->appendChild($self->createSVGLine(%args));
}

sub createSVGCircle {
    my $self = shift;
    my %args = @_;
    my $x = $args{x}; $x //= $self->width / 2;
    my $y = $args{y}; $y //= $self->height / 2;
    my $r = $args{r};

    my $lineTypeId = $args{lineTypeId};
    my $lineType = defined $lineTypeId ? $self->lineTypeHash->{$lineTypeId} : undef;
    my $attr = $args{attr};
    my $useStrokeDashCSSClasses = $args{useStrokeDashCSSClasses};

    my $circle = $self->svgDocument->createElement('circle');
    $circle->setAttribute('cx', sprintf('%.3f', $self->xx($x)));
    $circle->setAttribute('cy', sprintf('%.3f', $self->yy($y)));
    $circle->setAttribute('r',  sprintf('%.3f', $self->coordinate($r)));

    my $circumference = $self->coordinate($r) * pi2;
    my $nPoints;
    if (defined $args{dashSpacing}) {
        $nPoints = int(0.5 + $circumference / $self->coordinate($args{dashSpacing}));
        if ($nPoints) {
            $args{dashSpacing} = $circumference / $nPoints;
        } else {
            delete $args{dashSpacing};
        }
    }

    if (defined $lineTypeId) {
        my @cssClass = ($lineType->id);
        my $cssClass = $lineTypeId;
        if ($lineType && $lineType->isDashedOrDotted && defined $args{dashSpacing}) {
            my $strokeDashArray = strokeDashArray(%args);
            my $strokeDashOffset = strokeDashOffset(%args);
            if ($useStrokeDashCSSClasses) {
                my $sdaClassName = $self->getStrokeDashArrayClassName($strokeDashArray);
                my $sdoClassName = $self->getStrokeDashOffsetClassName($strokeDashOffset);
                push(@cssClass, $sdaClassName) if defined $sdaClassName;
                push(@cssClass, $sdoClassName) if defined $sdoClassName;
            } else {
                $circle->setAttribute('stroke-dasharray', $strokeDashArray);
                $circle->setAttribute('stroke-dashoffset', $strokeDashOffset);
            }
            push(@cssClass, 'dashed') if $lineType->isDashed;
            push(@cssClass, 'dotted') if $lineType->isDotted;
        }
        $circle->setAttribute('class', join(' ', @cssClass)) if scalar @cssClass;
    }

    if (eval { ref $attr eq 'HASH' }) {
        foreach my $name (sort keys %$attr) {
            $circle->setAttribute($name, $attr->{$name});
        }
    }
    return $circle;
}

sub createSVGLine {
    my $self = shift;
    my %args = @_;
    my $x1 = $args{x1} // $args{x} // ($self->width / 2);
    my $x2 = $args{x2} // $args{x} // ($self->width / 2);
    my $y1 = $args{y1} // $args{y} // ($self->height / 2);
    my $y2 = $args{y2} // $args{y} // ($self->height / 2);

    $x1 = $self->xx($x1);
    $x2 = $self->xx($x2);
    $y1 = $self->yy($y1);
    $y2 = $self->yy($y2);

    my $cx = $args{cx} // (($x1 + $x2) / 2);
    my $cy = $args{cy} // (($y1 + $y2) / 2);
    my $rotate = $args{rotate};
    my $length = $args{length};

    $cx = $self->xx($cx);
    $cy = $self->yy($cy);
    $length = $self->coordinate($args{length}) if defined $length;

    if (defined $rotate) {
        my $theta = $rotate * pi / 180;
        my $sin = sin($theta);
        my $cos = cos($theta);
        if ($x1 == $x2 && $y1 == $y2) { # a point
            my $x = $x1;
            my $y = $y1;
            $x -= $cx;
            $y -= $cy;
            ($x, $y) = ($x * $cos - $y * $sin, $x * $sin + $y * $cos);
            $x += $cx;
            $y += $cy;
            my $r = sqrt($self->width ** 2 + $self->height ** 2);
            if (defined $length) {
                $r = $length / 2;
            }
            $x1 = $x + $r * $sin;
            $y1 = $y - $r * $cos;
            $x2 = $x - $r * $sin;
            $y2 = $y + $r * $cos;
        } else {                # a line segment of nonzero length
            $x1 -= $cx;
            $y1 -= $cy;
            $x2 -= $cx;
            $y2 -= $cy;
            ($x1, $y1) = ($x1 * $cos - $y1 * $sin, $x1 * $sin + $y1 * $cos);
            ($x2, $y2) = ($x2 * $cos - $y2 * $sin, $x2 * $sin + $y2 * $cos);
            $x1 += $cx;
            $y1 += $cy;
            $x2 += $cx;
            $y2 += $cy;
        }
    }

    my $lineTypeId = $args{lineTypeId};
    my $lineType = defined $lineTypeId ? $self->lineTypeHash->{$lineTypeId} : undef;
    my $attr = $args{attr};
    my $useStrokeDashCSSClasses = $args{useStrokeDashCSSClasses};

    my $line = $self->svgDocument->createElement('line');
    $line->setAttribute('x1', sprintf('%.3f', $x1));
    $line->setAttribute('x2', sprintf('%.3f', $x2));
    $line->setAttribute('y1', sprintf('%.3f', $y1));
    $line->setAttribute('y2', sprintf('%.3f', $y2));

    $args{dashSpacing} = $self->coordinate($args{dashSpacing}) if defined $args{dashSpacing};
    $args{dashCenterAt} = sqrt(($y2 - $y1) ** 2 + ($x2 - $x1) ** 2) / 2;

    if (defined $lineTypeId) {
        my @cssClass = ($lineType->id);
        my $cssClass = $lineTypeId;
        if ($lineType && $lineType->isDashedOrDotted && defined $args{dashSpacing}) {
            my $strokeDashArray = strokeDashArray(%args);
            my $strokeDashOffset = strokeDashOffset(%args);
            if ($useStrokeDashCSSClasses) {
                my $sdaClassName = $self->getStrokeDashArrayClassName($strokeDashArray);
                my $sdoClassName = $self->getStrokeDashOffsetClassName($strokeDashOffset);
                push(@cssClass, $sdaClassName) if defined $sdaClassName;
                push(@cssClass, $sdoClassName) if defined $sdoClassName;
            } else {
                $line->setAttribute('stroke-dasharray', $strokeDashArray);
                $line->setAttribute('stroke-dashoffset', $strokeDashOffset);
            }
            push(@cssClass, 'dashed') if $lineType->isDashed;
            push(@cssClass, 'dotted') if $lineType->isDotted;
        }
        $line->setAttribute('class', join(' ', @cssClass)) if scalar @cssClass;
    }

    if (eval { ref $attr eq 'HASH' }) {
        foreach my $name (sort keys %$attr) {
            $line->setAttribute($name, $attr->{$name});
        }
    }
    return $line;
}

sub xx {
    my $self = shift;
    my $value = shift;
    return $self->coordinate($value, 'x');
}

sub yy {
    my $self = shift;
    my $value = shift;
    return $self->coordinate($value, 'y');
}

sub coordinate {
    my $self = shift;
    my $value = shift;
    my $axis = shift;
    my $multiple = 0;
    die("undefined coordinate") if !defined $value;
    if (eval { $value->isa('My::Printable::Paper::2::PointSeries') }) {
        my @points = $value->getPoints;
        return @points if wantarray;
        return \@points;
    }
    if (eval { ref $value eq 'ARRAY' }) {
        my @points = map { $self->coordinate($_, $axis) } @$value;
        return @points if wantarray;
        return \@points;
    }
    if ($value =~ m{^\s*$RE{num}{real}}) {
        return My::Printable::Paper::2::Coordinate::parse($value, $axis, $self);
    }
    $value = 'gridSpacingX' if $value eq 'gridSpacing' && $axis eq 'x';
    $value = 'gridSpacingY' if $value eq 'gridSpacing' && $axis eq 'y';
    $value = 'originX'      if $value eq 'origin'      && $axis eq 'x';
    $value = 'originY'      if $value eq 'origin'      && $axis eq 'y';
    if ($value =~ m{\|}) {
        my $xName = $`;
        my $yName = $';
        if (!defined $axis) {
            die("coordinate: $value must have axis specified");
        } elsif ($axis eq 'x') {
            $value = $xName;
        } elsif ($axis eq 'y') {
            $value = $yName;
        } else {
            die("coordinate: invalid axis $axis");
        }
    }
    if ($self->can($value)) {
        return $self->coordinate($self->$value, $axis);
    }
    die("can't parse '$value' as coordinate(s)");
}

sub toSVG {
    my $self = shift;
    return $self->svgDocument->toString(2);
}

sub getStrokeDashArrayAndOffset {
    my ($self, %args) = @_;
    my $axis        = $args{axis};
    my $coordinates = $args{coordinates};
    my $lineType    = $args{lineType};
    my $isClosed    = $args{isClosed};

    return undef if !$lineType->isDashedOrDotted;

    my $isPointSeries = eval {
        $coordinates->isa('My::Printable::Paper::2::PointSeries')
    };

    my @pt = $self->coordinate($coordinates, $axis);

    my $spacing = $isPointSeries ?
        $self->coordinate($coordinates->step, $axis) :
        $self->coordinate('gridSpacingX|gridSpacingY', $axis);

    my $start = 0;
    my $end   = $self->coordinate('width|height', $axis);
    my $isExtended             = 0;
    my $isExtendedHorizontally = 0;
    my $isExtendedVertically   = 0;
    if ($isClosed) {
        $start = $pt[0];
        $end   = $pt[$#pt];
    } else {
        my $isExtendedStart = $start <= $pt[0]    - $spacing;
        my $isExtendedEnd   = $end   >= $pt[$#pt] + $spacing;
        $isExtended = $isExtendedStart || $isExtendedEnd;
    }

    my $dashLength;
    my $dashSpacing;
    my $dashLineStart;
    my $dashCenterAt;

    if ($lineType->isDashed) {
        $dashLength = $spacing / 2;
    }
    if ($lineType->isDotted) {
        $dashLength = 0;
    }
    $dashSpacing = $spacing;
    if (!$isClosed) {
        $dashLineStart = $start;
        $dashCenterAt = $pt[0];
    }
    if ($lineType->isDashed) {
        $dashSpacing /= $lineType->dashes;
        $dashLength  /= $lineType->dashes;
    }
    if ($lineType->isDotted) {
        $dashSpacing /= $lineType->dots;
        $dashLength  /= $lineType->dots;
    }

    my %dashArgs = (
        dashLength    => $dashLength,
        dashSpacing   => $dashSpacing,
        dashLineStart => $dashLineStart,
        dashCenterAt  => $dashCenterAt,
    );

    my $strokeDashArray  = strokeDashArray(%dashArgs);
    my $strokeDashOffset = strokeDashOffset(%dashArgs);

    return ($strokeDashArray, $strokeDashOffset);
}

sub getGridStartEnd {
    my ($self, %args) = @_;
    my $axis        = $args{axis};
    my $coordinates = $args{coordinates};
    my $isClosed    = $args{isClosed};
    my $isPointSeries = eval {
        $coordinates->isa('My::Printable::Paper::2::PointSeries')
    };
    my @pt = $self->coordinate($coordinates, $axis);
    my $spacing = $isPointSeries ?
        $self->coordinate($coordinates->step, $axis) :
        $self->coordinate('gridSpacingX|gridSpacingY', $axis);
    my $start = 0;
    my $end = $self->coordinate('width|height', $axis);
    my $isExtended = 0;
    if ($isClosed) {
        $start = $pt[0];
        $end = $pt[$#pt];
    } else {
        my $isExtendedStart = $start <= $pt[0]    - $spacing;
        my $isExtendedEnd   = $end   >= $pt[$#pt] + $spacing;
        $isExtended = $isExtendedStart || $isExtendedEnd;
    }
    return ($start, $end, $isExtended);
}

sub minWidthHeight {
    my ($self) = @_;
    return min($self->width, $self->height);
}

sub maxWidthHeight {
    my ($self) = @_;
    return max($self->width, $self->height);
}

1;
