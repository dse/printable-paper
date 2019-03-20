package My::Printable::Paper::Document;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::ModifierList;
use My::Printable::Paper::Util qw(:const :around :trigger
                                  snapcmp flatten);
use My::Printable::Paper::Converter;
use My::Printable::Paper::Color qw(:const);

use XML::LibXML;
use Scalar::Util qw(refaddr);
use List::Util qw(max);

use Moo;

has id => (is => 'rw');

has filename => (is => 'rw', trigger => triggerWrapper(\&triggerFilename));

sub triggerFilename {
    my ($self, $filename) = @_;
    if (defined $filename && $filename !~ m{\.svg\z}i) {
        $filename .= '.svg';
        $self->filename($filename);
    }
}

has paperSizeName => (is => 'rw',
                      default => DEFAULT_PAPER_SIZE_NAME,
                      trigger => triggerWrapper(\&triggerPaperSizeName));

sub triggerPaperSizeName {
    my ($self, $spec) = @_;
    return unless defined $spec;
    my ($name, $width, $height, $unit_type) = My::Printable::Paper::SizeDefinitions->parse($spec);
    $self->width($width);
    $self->height($height);
    $self->unitType($unit_type);
    $self->setOrientationFromDimensions();
    $self->unitX->size($width);
    $self->unitY->size($height);
    $self->unitX->setPercentageBasis($width);
    $self->unitY->setPercentageBasis($height);
    $self->originX($width / 2);
    $self->originY($height / 2);
}

has width => (
    is => 'rw',
    default => DEFAULT_WIDTH,
    trigger => triggerWrapper(\&triggerWidth),
);

has height => (
    is => 'rw',
    default => DEFAULT_HEIGHT,
    trigger => triggerWrapper(\&triggerHeight),
);

sub triggerWidth {
    my ($self, $value) = @_;
    my ($pt, $unit_type) = $self->pt($value);
    $self->width($pt);

    $self->unitType($unit_type);
    $self->paperSizeName(undef);
    $self->unitX->setPercentageBasis($pt);
    $self->originX($pt / 2);
    $self->setOrientationFromDimensions();
};

sub triggerHeight {
    my ($self, $value) = @_;
    my ($pt, $unit_type) = $self->pt($value);
    $self->height($pt);

    $self->unitType($unit_type);
    $self->paperSizeName(undef);
    $self->unitY->setPercentageBasis($pt);
    $self->originY($pt / 2);
    $self->setOrientationFromDimensions();
};

# 'imperial', 'metric';
has unitType => (is => 'rw', default => DEFAULT_UNIT_TYPE);

# 'color', 'grayscale', 'black'
has colorType => (is => 'rw', default => DEFAULT_COLOR_TYPE);

# 'seyes', etc.
has rulingName => (is => 'rw');

# in points from RESPECTIVE edge of paper
has leftMargin   => (is => 'rw', default => 0, trigger => triggerUnit('leftMargin',   axis => 'x', edge => 'near'));
has rightMargin  => (is => 'rw', default => 0, trigger => triggerUnit('rightMargin',  axis => 'x', edge => 'far'));
has topMargin    => (is => 'rw', default => 0, trigger => triggerUnit('topMargin',    axis => 'y', edge => 'near'));
has bottomMargin => (is => 'rw', default => 0, trigger => triggerUnit('bottomMargin', axis => 'y', edge => 'far'));

# in points from LEFT or TOP edge of paper
sub leftMarginX {
    my $self = shift;
    die("leftMarginX is read-only") if scalar @_;
    return $self->leftMargin;
}
sub rightMarginX {
    my $self = shift;
    die("rightMarginX is read-only") if scalar @_;
    return $self->width - $self->rightMargin;
}
sub topMarginY {
    my $self = shift;
    die("topMarginY is read-only") if scalar @_;
    return $self->topMargin;
}
sub bottomMarginY {
    my $self = shift;
    die("bottomMarginY is read-only") if scalar @_;
    return $self->height - $self->bottomMargin;
}

# My::Printable::Paper::Unit
has unit => (is => 'rw');
has unitX => (is => 'rw');
has unitY => (is => 'rw');

has modifiers => (
    is => 'rw',
    default => sub { return My::Printable::Paper::ModifierList->new(); },
);
has elements => (
    is => 'rw',
    default => sub { return []; },         # via appendElement
);
has elementsById => (
    is => 'rw',
    default => sub { return {}; },         # via appendElement
);

has originX => (is => 'rw', default => DEFAULT_WIDTH / 2,  trigger => triggerUnitX('originX'));
has originY => (is => 'rw', default => DEFAULT_HEIGHT / 2, trigger => triggerUnitY('originY'));

has isGenerated => (is => 'rw', default => 0);
has additionalStyles => (is => 'rw');

has svgDocument => (
    is => 'rw',
    lazy => 1, default => sub {
        my ($self) = @_;
        my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
        return $doc;
    },
    clearer => 'deleteSVGDocument',
);

has svgRoot => (
    is => 'rw',
    lazy => 1, default => sub {
        my ($self) = @_;
        my $width = $self->width;
        my $height = $self->height;
        my $doc = $self->svgDocument;
        my $viewBox = sprintf("%s %s %s %s", map { round3($_) } (0, 0, $width, $height));
        my $root = $doc->createElement("svg");
        $root->setAttribute("width", round3($width) . "pt");
        $root->setAttribute("height", round3($height) . "pt");
        $root->setAttribute("viewBox", $viewBox);
        $root->setAttribute("xmlns", "http://www.w3.org/2000/svg");
        $doc->setDocumentElement($root);
        return $root;
    },
    clearer => 'deleteSVGRoot',
);

after 'svgRoot' => sub {
    my ($self) = @_;

    # Recursion avoidance is required because some of the methods we
    # call call svgRoot.
    state $in = 0;
    return if $in;
    $in += 1;

    $self->svgDefs;
    $self->svgStyle;

    # Recursion avoidance is complete.
    $in -= 1;
};

has svgDefs => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        my $doc = $self->svgDocument;
        my $root = $self->svgRoot;
        my $defs = $doc->createElement('defs');
        $root->appendChild($defs);
        return $defs;
    },
    clearer => 'deleteSVGDefs',
);

has svgInkscapeBugWorkaroundFilter => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        my $filter = $self->svgDocument->createElement('filter');
        $filter->setAttribute('id', 'inkscapeBugWorkaroundFilter');

        # an arbitrarily selected filter that does nothing.
        my $feOffset = $self->svgDocument->createElement('feOffset');
        $feOffset->setAttribute('in', 'SourceGraphic');
        $feOffset->setAttribute('dx', '0');
        $feOffset->setAttribute('dy', '0');
        $filter->appendChild($feOffset);

        $self->svgDefs->appendChild($filter);
        return $filter;
    },
    clearer => 'deleteSVGInkscapeBugWorkaroundFilter',
);

has svgStyle => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        return $self->addStyleElement(
            $self->doubleCurly($self->defaultStyles),
            $self->doubleCurly($self->additionalStyles),
        );
    },
    clearer => 'deleteSVGStyle',
);

has svgContext => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        my $ctx = XML::LibXML::XPathContext->new($self->svgDocument);
        $ctx->registerNs('svg', 'http://www.w3.org/2000/svg');
        return $ctx;
    },
    clearer => 'deleteSVGContext',
);

has dryRun  => (is => 'rw', default => 0);
has verbose => (is => 'rw', default => 0);

has orientation => (is => 'rw', default => DEFAULT_ORIENTATION, trigger => triggerWrapper(\&triggerOrientation));

sub triggerOrientation {
    my ($self, $orientation) = @_;

    my $width = $self->width;
    my $height = $self->height;

    my $swap = 0;
    if ($orientation eq 'portrait') {
        if (snapcmp($width, $height) > 0) {
            $swap = 1;
        }
    } elsif ($orientation eq 'landscape') {
        if (snapcmp($height, $width) > 0) {
            $swap = 1;
        }
    } else {
        die("When setting orientation, you must use 'landscape' or 'portrait'.");
    }

    if ($swap) {
        $self->paperSizeName(undef);
        my $unitX = $self->unitX;
        my $unitY = $self->unitY;
        my $originX = $self->originX;
        my $originY = $self->originY;
        $self->width($height);
        $self->height($width);
        $self->unitY($unitX);
        $self->unitX($unitY);
        $self->originY($originX);
        $self->originX($originY);
    }
}

sub setOrientationFromDimensions {
    my ($self) = @_;
    my $width = $self->width;
    my $height = $self->height;
    my $cmp = snapcmp($width, $height);
    if ($cmp == 0) {
        $self->orientation('square');
    } elsif ($cmp < 0) {
        $self->orientation('portrait');
    } else {
        $self->orientation('landscape');
    }
}

has 'leftClip'   => (is => 'rw', default => 0, trigger => triggerUnitX('leftClip'));
has 'rightClip'  => (is => 'rw', default => 0, trigger => triggerUnitX('rightClip'));
has 'topClip'    => (is => 'rw', default => 0, trigger => triggerUnitX('topClip'));
has 'bottomClip' => (is => 'rw', default => 0, trigger => triggerUnitX('bottomClip'));

sub setClip {
    my ($self, $clip) = @_;
    $self->leftClip($clip);
    $self->rightClip($clip);
    $self->topClip($clip);
    $self->bottomClip($clip);
}

sub addStyleElement {
    my ($self, @cssText) = @_;
    my $cssText = join("\n\n", grep { defined $_ && m{\S} } @cssText);
    $cssText =~ s{\R}{\n}g;
    $cssText = "\n" . $cssText;
    $cssText =~ s{\s*\z}{\n  };
    my $doc = $self->svgDocument;
    my $root = $self->svgRoot;
    my $style = $doc->createElement('style');
    $style->appendText($cssText);
    my $after = $self->findStyleNodeInsertionPoint();
    if ($after) {
        $root->insertAfter($style, $after);
    } else {
        $root->insertBefore($style, $root->firstChild);
    }
    return $style;
}

has 'clipPath' => (is => 'rw');

sub addOrRemoveClipPathDefinition {
    my ($self) = @_;
    if ($self->clipPath) {
        my $defs = $self->svgDefs;
        $defs->removeChild($self->clipPath);
        $self->clipPath(undef);
    }
    if ($self->leftClip > 0 || $self->rightClip > 0 ||
            $self->topClip > 0 || $self->bottomClip > 0) {
        my $clipX = $self->leftClip;
        my $clipY = $self->topClip;
        my $clipWidth = $self->width - $self->leftClip - $self->rightClip;
        my $clipHeight = $self->height - $self->topClip - $self->bottomClip;
        my $defs = $self->svgDefs;
        my $clipPath = $self->svgDocument->createElement('clipPath');
        $clipPath->setAttribute('id', 'document-clip-path');
        my $rect = $self->svgDocument->createElement('rect');
        $rect->setAttribute('x', sprintf('%g', $clipX));
        $rect->setAttribute('y', sprintf('%g', $clipY));
        $rect->setAttribute('width', sprintf('%g', $clipWidth));
        $rect->setAttribute('height', sprintf('%g', $clipHeight));
        $defs->appendChild($clipPath);
        $clipPath->appendChild($rect);
        $self->clipPath($clipPath);
    }
}

sub findStyleNodeInsertionPoint {
    my ($self) = @_;
    my $doc = $self->svgDocument;
    my ($after) = $self->svgContext->findnodes('svg/style');
    return $after;
}

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(round3);
use My::Printable::Paper::Unit;
use My::Printable::Paper::SizeDefinitions;

sub deleteSVG {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->deleteSVGLayer();
    }
    $self->deleteSVGStyle();
    if (USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND) {
        $self->deleteSVGInkscapeBugWorkaroundFilter();
    }
    $self->deleteSVGDefs();
    $self->deleteSVGRoot();
    $self->deleteSVGContext();
    $self->deleteSVGDocument();
    $self->resetCSSClasses();
    $self->isGenerated(0);
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

sub BUILD {
    my ($self) = @_;
    $self->unit(My::Printable::Paper::Unit->new());
    $self->unitX(My::Printable::Paper::Unit->new());
    $self->unitY(My::Printable::Paper::Unit->new());
    $self->unitX->size($self->width);
    $self->unitY->size($self->height);
    $self->unitX->setPercentageBasis($self->width);
    $self->unitY->setPercentageBasis($self->height);
    $self->unitX->axis("x");
    $self->unitY->axis("y");
}

sub reset {
    my ($self) = @_;
    $self->elements([]);
    $self->elementsById({});
}

sub setMargins {
    my ($self, $value) = @_;
    $self->leftMargin($value);
    $self->rightMargin($value);
    $self->topMargin($value);
    $self->bottomMargin($value);
}

sub setHorizontalMargins {
    my ($self, $value) = @_;
    $self->leftMargin($value);
    $self->rightMargin($value);
}

sub setVerticalMargins {
    my ($self, $value) = @_;
    $self->topMargin($value);
    $self->bottomMargin($value);
}

sub setUnit {
    my ($self, $value) = @_;
    $self->unit->addUnit("unit", scalar($self->pt($value)));
    $self->unitX->addUnit("unit", scalar($self->ptX($value)));
    $self->unitY->addUnit("unit", scalar($self->ptY($value)));
}

has disableDeveloperMark => (is => 'rw', default => 0);

sub generate {
    my ($self) = @_;
    $self->deleteSVG();
    $self->forEach("compute");
    $self->forEach("snap");
    $self->forEach("chop");
    $self->forEach("chopDocumentMargins");
    $self->forEach("extend");
    # excluding individual coordinates, if elemented, would go here.

    $self->addOrRemoveClipPathDefinition();

    $self->forEach("draw");
    if (!$self->disableDeveloperMark) {
        $self->leaveAMark();
    }
    $self->isGenerated(1);
}

sub leaveAMark {
    my ($self) = @_;

    my $x = $self->ptX('50%');
    my $y = $self->ptY('1/4in from bottom');
    my $text_data = 'https://github.com/dse/printable-paper';
    my $text_style;
    if ($^O =~ m{^darwin}) {
        $text_style = 'font-family: "Courier", "Courier New", monospace; font-size: 6pt;';
    } else {
        $text_style = 'font-family: "Courier New", "Courier", monospace; font-size: 6pt;';
    }
    my $text_color =
        $self->colorType eq 'color'     ? COLOR_BLUE :
        $self->colorType eq 'grayscale' ? COLOR_GRAY :
        COLOR_BLACK;
    my $add_rectangle_stroke = 0;
    {
        my $rect_width = $self->ptX('2.625in');
        my $rect_height = $self->ptY('12pt');
        my $rect_x = $self->ptX('50%') - $rect_width / 2;
        my $rect_y = $self->ptY('1/4 in from bottom') - $rect_height * 2 / 3;
        my $rect = $self->svgDocument->createElement('rect');
        $rect->setAttribute('x', $rect_x);
        $rect->setAttribute('y', $rect_y);
        $rect->setAttribute('width', $rect_width);
        $rect->setAttribute('height', $rect_height);
        $rect->setAttribute('fill', '#ffffff');
        if ($add_rectangle_stroke) {
            $rect->setAttribute('stroke', $text_color);
            $rect->setAttribute('stroke-width', $self->pt('2/600in'));
            $rect->setAttribute('rx', '2pt');
            $rect->setAttribute('ry', '2pt');
        } else {
            $rect->setAttribute('stroke', 'none');
            $rect->setAttribute('stroke-width', '0px');
        }
        if ($self->clipPath) {
            $rect->setAttribute('clip-path', 'url(#document-clip-path)');
        }
        $self->svgRoot->appendChild($rect);
    }
    {
        my $text = $self->svgDocument->createElement('text');
        $text->setAttribute('x', $x);
        $text->setAttribute('y', $y);
        $text->setAttribute('text-anchor', 'middle');
        $text->setAttribute('fill', $text_color);
        $text->setAttribute('stroke', 'none');
        $text->setAttribute('stroke-width', '0');
        $text->setAttribute('style', $text_style);
        $text->appendText($text_data);
        if ($self->clipPath) {
            $text->setAttribute('clip-path', 'url(#document-clip-path)');
        }
        $self->svgRoot->appendChild($text);
    }
}

sub forEach {
    my ($self, $method, @args) = @_;
    foreach my $element (@{$self->elements}) {
        $element->$method(@args) if $element->can($method);
    }
}

sub print {
    my ($self) = @_;
    my $filename = $self->filename;
    if (defined $filename) {
        $self->printToFile($filename);
        $self->generateFormats();
    } else {
        $self->printToHandle(\*STDOUT);
    }
}

use File::Basename qw(dirname);
use File::Path qw(make_path);

sub printToFile {
    my ($self, $filename) = @_;
    if ($self->dryRun) {
        print("would write SVG to $filename\n");
        return;
    }
    my $fh;
    my $save_filename = $self->filename;
    $self->filename($filename);
    make_path(dirname($filename));
    my $temp_filename = "${filename}.tmp.svg";
    open($fh, ">", $temp_filename) or die("Cannot write $temp_filename: $!\n");
    $self->printToHandle($fh);
    close($fh) or die("Cannot close $temp_filename: $!\n");
    rename($temp_filename, $filename) or die("Cannot rename $temp_filename to $filename: $!\n");
    $self->filename($save_filename);
    return;
}

has generatePDF      => (is => 'rw', default => 0);
has generatePS       => (is => 'rw', default => 0);
has generate2Page2Up => (is => 'rw', default => 0);
has generate2Page4Up => (is => 'rw', default => 0);
has generate2Page    => (is => 'rw', default => 0);
has generate2Up      => (is => 'rw', default => 0);
has generate4Up      => (is => 'rw', default => 0);

sub generateFormats {
    my ($self) = @_;
    my $filename = $self->filename;
    my $baseFilename = $filename;
    $baseFilename =~ s{\.svg\z}{}i;

    my $pdfFilename              = $baseFilename . '.pdf';
    my $psFilename               = $baseFilename . '.ps';
    my $twoPagePDFFilename       = $baseFilename . '.2page.pdf';
    my $twoPagePSFilename        = $baseFilename . '.2page.ps';
    my $twoUpPDFFilename         = $baseFilename . '.2up.pdf';
    my $twoUpPSFilename          = $baseFilename . '.2up.ps';
    my $fourUpPDFFilename        = $baseFilename . '.4up.pdf';
    my $fourUpPSFilename         = $baseFilename . '.4up.ps';
    my $twoPageTwoUpPDFFilename  = $baseFilename . '.2page2up.pdf';
    my $twoPageTwoUpPSFilename   = $baseFilename . '.2page2up.ps';
    my $twoPageFourUpPDFFilename = $baseFilename . '.2page4up.pdf';
    my $twoPageFourUpPSFilename  = $baseFilename . '.2page4up.ps';

    my $converter = My::Printable::Paper::Converter->new();
    $converter->width($self->width);
    $converter->height($self->height);

    my $generatePDF;
    my $generatePS;
    my $generate2PagePDF;
    my $generate2PagePS;
    my $generate2UpPDF;
    my $generate2UpPS;
    my $generate4UpPDF;
    my $generate4UpPS;
    my $generate2Page2UpPDF;
    my $generate2Page2UpPS;
    my $generate2Page4UpPDF;
    my $generate2Page4UpPS;

    if ($self->generatePDF) {
        $generatePDF = 1;
    }
    if ($self->generatePS) {
        $generatePS = 1;
    }
    if ($self->generate2Page) {
        if ($self->generatePDF) {
            $generate2PagePDF = 1;
        }
        if ($self->generatePS) {
            $generate2PagePS = 1;
        }
    }
    if ($self->generate2Up) {
        if ($self->generatePDF) {
            $generate2UpPDF = 1;
        }
        if ($self->generatePS) {
            $generate2UpPS = 1;
        }
    }
    if ($self->generate2Page2Up) {
        if ($self->generatePDF) {
            $generate2Page2UpPDF = 1;
        }
        if ($self->generatePS) {
            $generate2Page2UpPS = 1;
        }
    }

    if ($self->generate4Up) {
        if ($self->generatePDF) {
            $generate4UpPDF = 1;
        }
        if ($self->generatePS) {
            $generate4UpPS = 1;
        }
    }
    if ($self->generate2Page4Up) {
        if ($self->generatePDF) {
            $generate2Page4UpPDF = 1;
        }
        if ($self->generatePS) {
            $generate2Page4UpPS = 1;
        }
    }

    $converter->dryRun($self->dryRun);
    $converter->verbose($self->verbose);

    if ($generatePDF) {
        $converter->convertSVGToPDF($filename, $pdfFilename);
    }
    if ($generatePS) {
        $converter->convertSVGToPS($filename, $psFilename);
    }

    if ($generate2PagePDF) {
        $converter->convertPDFTo2PagePDF($pdfFilename, $twoPagePDFFilename);
    }
    if ($generate2PagePS) {
        $converter->convertPSTo2PagePS($psFilename, $twoPagePSFilename);
    }

    if ($generate2UpPDF) {
        $converter->convertPDFToNPageNUpPDF($pdfFilename, $twoUpPDFFilename, 1, 2);
    }
    if ($generate2UpPS) {
        $converter->convertPSToNPageNUpPS($psFilename, $twoUpPSFilename, 1, 2);
    }
    if ($generate2Page2UpPDF) {
        $converter->convertPDFToNPageNUpPDF($pdfFilename, $twoPageTwoUpPDFFilename, 2, 2);
    }
    if ($generate2Page2UpPS) {
        $converter->convertPSToNPageNUpPS($psFilename, $twoPageTwoUpPSFilename, 2, 2);
    }

    if ($generate4UpPDF) {
        $converter->convertPDFToNPageNUpPDF($pdfFilename, $fourUpPDFFilename, 1, 4);
    }
    if ($generate4UpPS) {
        $converter->convertPSToNPageNUpPS($psFilename, $fourUpPSFilename, 1, 4);
    }
    if ($generate2Page4UpPDF) {
        $converter->convertPDFToNPageNUpPDF($pdfFilename, $twoPageFourUpPDFFilename, 2, 4);
    }
    if ($generate2Page4UpPS) {
        $converter->convertPSToNPageNUpPS($psFilename, $twoPageFourUpPSFilename, 2, 4);
    }
}

sub printToHandle {
    my ($self, $handle) = @_;
    if (!$self->isGenerated) {
        $self->generate();
    }
    print $handle $self->svgDocument->toString(2);
}

sub appendElement {
    my ($self, $element) = @_;
    if (!defined $element) {
        return;
    }
    if (grep { $_ eq $element } @{$self->elements}) {
        return;
    }
    $element->document($self);
    my $id = $element->id;
    if (defined $id) {
        $self->elementsById->{$id} = $element;
    }
    push(@{$self->elements}, $element);
}

sub appendSVGLayer {
    my ($self, $svg_layer) = @_;
    return if $svg_layer->ownerDocument == $self->svgDocument;
    if ($self->clipPath) {
        $svg_layer->setAttribute('clip-path', 'url(#document-clip-path)');
    }
    $self->svgRoot->appendChild($svg_layer);
}

sub appendToSVGDefs {
    my ($self, $svg_object) = @_;
    return if $svg_object->ownerDocument == $self->svgDocument;
    $self->svgDefs->appendChild($svg_object);
}

sub isPaperSizeClass {
    my ($self, $size) = @_;
    my $sqpt_size = My::Printable::Paper::SizeDefinitions->get_square_points($size);
    my $sqpt      = $self->getSquarePoints();
    return 0 if !$sqpt_size || !$sqpt;
    my $ratio = $sqpt / $sqpt_size;
    return $ratio >= 0.8 && $ratio <= 1.25;
}

sub isA4SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('letter') || $self->isPaperSizeClass('a4');
}

sub isA5SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('halfletter') || $self->isPaperSizeClass('a5');
}

sub isA6SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('quarterletter') || $self->isPaperSizeClass('a6');
}

sub isTravelersClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('travelers');
}

sub getSquarePoints {
    my ($self) = @_;
    my $width = $self->width;
    my $height = $self->height;
    return 0 if !$width;
    return 0 if !$height;
    return $width * $height;
}

sub defaultStyles {
    my ($self) = @_;
    return <<"EOF";
        .line, .regular-line, .major-line, .feint-line,
        .dot,  .regular-dot,  .major-dot,  .feint-dot,
        .margin-line {
            stroke-linecap: round; stroke-linejoin: round;
        }
        .stroke-linecap-butt    { stroke-linecap:  butt;   }
        .stroke-linecap-round   { stroke-linecap:  round;  }
        .stroke-linecap-square  { stroke-linecap:  square; }
        .stroke-linejoin-butt   { stroke-linejoin: butt;   }
        .stroke-linejoin-round  { stroke-linejoin: round;  }
        .stroke-linejoin-square { stroke-linejoin: square; }
        .rectangle { fill: #ffffff; }
EOF
}

# {{ 1/600 in }} => 0.12pt
# {{ [[ sqrt(2) ]] in }} => about 101.82pt
# {{ sqrt(2) @ in }} => about 101.82pt

sub doubleCurly {
    my ($self, $text, $format) = @_;
    if (!defined $text) {
        if (scalar @_ >= 2) {
            return undef;
        }
        return;
    }
    $text =~ s{\{\{\s*(.*?)\s*\}\}}{$self->doubleCurlyExpr($1, $format)}gxe;
    return $text;
}

sub doubleCurlyExpr {
    my ($self, $expr, $format) = @_;
    if ($expr =~ m{^\s*(.*?)\s*@\s*(.*?)\s*$}) {
        $expr = $self->doubleBracketExpr($1) . $2;
    } else {
        $expr =~ s{\[\[(.*?)\]\]}{$self->doubleBracketExpr($1)}gxe;
    }
    my $pt = $self->unit->pt($expr);
    if (defined $format) {
        $pt = sprintf($format, $pt);
    }
    return $pt . 'px';
}

sub doubleBracketExpr {
    my ($self, $expr) = @_;
    return eval $expr;
}

has cssClasses      => (is => 'rw', builder => sub { return {}; });
has cssClassCounter => (is => 'rw', default => 0);

sub resetCSSClasses {
    my ($self) = @_;
    $self->cssClasses({});
    $self->cssClassCounter(0);
}

sub styleToCSSClass {
    my ($self, $style) = @_;
    my $cssClasses = $self->cssClasses;
    return $cssClasses->{$style} if exists $cssClasses->{$style};
    my $class = $cssClasses->{$style} = 'class-' . $self->cssClassCounter;
    $self->cssClassCounter($self->cssClassCounter + 1);
    return $class;
}

sub appendCSSClass {
    my ($self, $string, @add_classes) = @_;
    my @classes;
    if (defined $string) {
        @classes = split(/\s+/, trim($string));
    }
    foreach my $class (@add_classes) {
        push(@classes, $class) unless grep { $_ eq $class } @classes;
    }
    return join(" ", @classes);
}

sub getElements {
    my ($self, @elements) = @_;
    @elements = flatten(@elements);
    return grep { defined $_ } map { $self->getElement($_) } @elements;
}

sub getElement {
    my ($self, $whatever) = @_;
    if (!defined $whatever) {
        return;
    }
    if (eval { $whatever->isa('My::Printable::Paper::Element') }) {
        return $whatever;
    }
    my $element = $self->elementsById->{$whatever};
    return $element;
}

sub leftVisibleBoundaryX {
    my ($self) = @_;
    my $clip   = $self->leftClip;
    my $margin = $self->leftMargin;
    return max(0, $clip, $margin);
}
sub rightVisibleBoundaryX {
    my ($self) = @_;
    my $clip   = $self->rightClip;
    my $margin = $self->rightMargin;
    return max(0, $clip, $margin);
}
sub topVisibleBoundaryY {
    my ($self) = @_;
    my $clip   = $self->topClip;
    my $margin = $self->topMargin;
    return max(0, $clip, $margin);
}
sub bottomVisibleBoundaryY {
    my ($self) = @_;
    my $clip   = $self->bottomClip;
    my $margin = $self->bottomMargin;
    return max(0, $clip, $margin);
}

1;
