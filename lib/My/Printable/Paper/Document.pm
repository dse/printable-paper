package My::Printable::Paper::Document;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::ModifierList;
use My::Printable::Paper::Util qw(:const snapcmp);
use My::Printable::Paper::Converter;
use My::Printable::Paper::Color qw(:const);

use XML::LibXML;
use Scalar::Util qw(refaddr);

use Moo;

has 'id' => (is => 'rw');

has 'rawFilename' => (is => 'rw');

use constant DEFAULT_PAPER_SIZE_NAME => 'letter';
use constant DEFAULT_WIDTH           => 612;
use constant DEFAULT_HEIGHT          => 792;
use constant DEFAULT_ORIENTATION     => 'portrait';
use constant DEFAULT_UNIT_TYPE       => 'imperial';
use constant DEFAULT_COLOR_TYPE      => 'color';

sub filename {
    my $self = shift;
    if (scalar @_) {
        my $filename = shift;
        if (defined $filename && $filename !~ m{\.svg\z}i) {
            $filename .= '.svg';
        }
        return $self->rawFilename($filename);
    }
    return $self->rawFilename;
}

has 'rawPaperSizeName' => (
    is => 'rw',
    default => DEFAULT_PAPER_SIZE_NAME,
);

sub paperSizeName {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawPaperSizeName;
    }
    my $spec = shift;
    my ($name, $width, $height, $unit_type) = My::Printable::Paper::Sizes->parse($spec);
    $self->unitType($unit_type);
    $self->rawWidth($width);
    $self->rawHeight($height);
    $self->setOrientationFromDimensions();
    $self->unitX->size($width);
    $self->unitY->size($height);
    $self->unitX->setPercentageBasis($width);
    $self->unitY->setPercentageBasis($height);
    $self->originX($width / 2);
    $self->originY($height / 2);
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
    $self->rawPaperSizeName($spec);
}

has 'rawWidth' => (
    is => 'rw',
    default => DEFAULT_WIDTH,
);
sub width {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawWidth;
    }
    my $value = shift;
    my ($pt, $unit_type) = $self->pt($value);
    $self->unitType($unit_type);
    $self->rawPaperSizeName(undef);
    $self->unitX->setPercentageBasis($pt);
    $self->originX($pt / 2);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
    $self->rawWidth($pt);
    $self->setOrientationFromDimensions();
};

has 'rawHeight' => (
    is => 'rw',
    default => DEFAULT_HEIGHT,
);
sub height {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawHeight;
    }
    my $value = shift;
    my ($pt, $unit_type) = $self->pt($value);
    $self->unitType($unit_type);
    $self->rawPaperSizeName(undef);
    $self->unitY->setPercentageBasis($pt);
    $self->originY($pt / 2);
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->rawHeight($pt);
    $self->setOrientationFromDimensions();
};

# 'imperial', 'metric';
has 'unitType' => (is => 'rw', default => DEFAULT_UNIT_TYPE);

# 'color', 'grayscale', 'black'
has 'colorType' => (is => 'rw', default => DEFAULT_COLOR_TYPE);

# 'seyes', etc.
has 'rulingName' => (is => 'rw');

has 'leftMarginX' => (is => 'rw');              # in pt, left = 0
has 'rightMarginX' => (is => 'rw');             # in pt, left = 0
has 'topMarginY' => (is => 'rw');               # in pt, top = 0
has 'bottomMarginY' => (is => 'rw');            # in pt, top = 0

# My::Printable::Paper::Unit
has 'unit' => (is => 'rw');
has 'unitX' => (is => 'rw');
has 'unitY' => (is => 'rw');

has 'modifiers' => (
    is => 'rw',
    default => sub { return My::Printable::Paper::ModifierList->new(); },
);
has 'elements' => (
    is => 'rw',
    default => sub { return []; },         # via appendElement
);
has 'elementsById' => (
    is => 'rw',
    default => sub { return {}; },         # via appendElement
);

has 'originX' => (is => 'rw', default => DEFAULT_WIDTH / 2);
has 'originY' => (is => 'rw', default => DEFAULT_HEIGHT / 2);

around 'originX' => sub {
    my $orig = shift;
    my $self = shift;
    if (scalar @_) {
        my $value = shift;
        return $self->$orig($self->ptX($value));
    }
    return $self->$orig();
};
around 'originY' => sub {
    my $orig = shift;
    my $self = shift;
    if (scalar @_) {
        my $value = shift;
        return $self->$orig($self->ptY($value));
    }
    return $self->$orig();
};

has 'isGenerated' => (is => 'rw', default => 0);
has 'additionalStyles' => (is => 'rw');

has 'svgDocument' => (
    is => 'rw',
    lazy => 1, default => sub {
        my ($self) = @_;
        my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
        return $doc;
    },
    clearer => 'deleteSVGDocument',
);

has 'svgRoot' => (
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

has 'svgDefs' => (
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

has 'svgInkscapeBugWorkaroundFilter' => (
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

has 'svgStyle' => (
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

has 'svgContext' => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        my $ctx = XML::LibXML::XPathContext->new($self->svgDocument);
        $ctx->registerNs('svg', 'http://www.w3.org/2000/svg');
        return $ctx;
    },
    clearer => 'deleteSVGContext',
);

has 'dryRun'  => (is => 'rw', default => 0);
has 'verbose' => (is => 'rw', default => 0);

has 'edgeMargin' => (is => 'rw', default => 18); # 0.25in

has 'rawOrientation' => (is => 'rw', default => DEFAULT_ORIENTATION);
sub orientation {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawOrientation;
    }
    my $orientation = shift;

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
        $self->rawPaperSizeName(undef);
        my $unitX = $self->unitX;
        my $unitY = $self->unitY;
        my $originX = $self->originX;
        my $originY = $self->originY;
        $self->rawWidth($height);
        $self->rawHeight($width);
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
        $self->rawOrientation('square');
    } elsif ($cmp < 0) {
        $self->rawOrientation('portrait');
    } else {
        $self->rawOrientation('landscape');
    }
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

sub findStyleNodeInsertionPoint {
    my ($self) = @_;
    my $doc = $self->svgDocument;
    my ($after) = $self->svgContext->findnodes('svg/style');
    return $after;
}

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(round3);
use My::Printable::Paper::Unit;
use My::Printable::Paper::Sizes;

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
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
}

sub reset {
    my ($self) = @_;
    $self->elements([]);
    $self->elementsById({});
}

sub setLeftMargin {
    my ($self, $value) = @_;
    $self->leftMarginX($self->ptX($value));
}

sub setRightMargin {
    my ($self, $value) = @_;
    my ($pt, $unit_type, $is_from_end) = $self->ptX($value);
    if ($is_from_end) {
        $self->rightMarginX($self->ptX($value));
    } else {
        $self->rightMarginX($self->width - $self->ptX($value));
    }
}

sub setTopMargin {
    my ($self, $value) = @_;
    $self->topMarginY($self->ptY($value));
}

sub setBottomMargin {
    my ($self, $value) = @_;
    my ($pt, $unit_type, $is_from_end) = $self->ptY($value);
    if ($is_from_end) {
        $self->bottomMarginY($self->ptY($value));
    } else {
        $self->bottomMarginY($self->height - $self->ptY($value));
    }
}

sub setUnit {
    my ($self, $value) = @_;
    $self->unit->addUnit("unit", scalar($self->pt($value)));
    $self->unitX->addUnit("unit", scalar($self->ptX($value)));
    $self->unitY->addUnit("unit", scalar($self->ptY($value)));
}

sub generate {
    my ($self) = @_;
    $self->deleteSVG();
    $self->forEach("compute");
    $self->forEach("snap");
    $self->forEach("chop");
    $self->forEach("chopDocumentMargins");
    $self->forEach("extend");
    # excluding individual coordinates, if elemented, would go here.
    $self->forEach("draw");
    $self->leaveAMark();
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

has 'generatePDF'      => (is => 'rw', default => 0);
has 'generatePS'       => (is => 'rw', default => 0);
has 'generate2Page2Up' => (is => 'rw', default => 0);
has 'generate2Page4Up' => (is => 'rw', default => 0);
has 'generate2Page'    => (is => 'rw', default => 0);
has 'generate2Up'      => (is => 'rw', default => 0);
has 'generate4Up'      => (is => 'rw', default => 0);

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
    $self->svgRoot->appendChild($svg_layer);
}

sub appendToSVGDefs {
    my ($self, $svg_object) = @_;
    return if $svg_object->ownerDocument == $self->svgDocument;
    $self->svgDefs->appendChild($svg_object);
}

sub isPaperSizeClass {
    my ($self, $size) = @_;
    my $sqpt_size = My::Printable::Paper::Sizes->get_square_points($size);
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
        .line, .dot, .major-line, .feint-line, .margin-line { stroke-linecap: round; }
        .stroke-linecap-butt   { stroke-linecap: butt; }
        .stroke-linecap-round  { stroke-linecap: round; }
        .stroke-linecap-square { stroke-linecap: square; }
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

has 'cssClasses'      => (is => 'rw', builder => sub { return {}; });
has 'cssClassCounter' => (is => 'rw', default => 0);

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

1;
