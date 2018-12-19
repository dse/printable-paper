package My::Printable::Document;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::ModifierList;
use My::Printable::Util qw(:const);

use XML::LibXML;
use Scalar::Util qw(refaddr);

use Moo;

has 'id' => (is => 'rw');
has 'filename' => (is => 'rw');
has 'rawPaperSizeName' => (
    is => 'rw',
    default => 'letter',
);

sub paperSizeName {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawPaperSizeName;
    }
    my $spec = shift;
    my ($name, $width, $height, $unit_type) = My::Printable::PaperSizes->parse($spec);
    $self->unitType($unit_type);
    $self->rawWidth($width);
    $self->rawHeight($height);
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
    default => 612,
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
};

has 'rawHeight' => (
    is => 'rw',
    default => 792,
);
sub height {
    my $self = shift;
    if (!scalar @_) {
        return $self->rawHeight;
    }
    my $value = shift;
    my ($pt, $unit_type) = $self->pt($value);
    $self->unitType($unit_type);
    $self->rawHeight($pt);
    $self->rawPaperSizeName(undef);
    $self->unitY->setPercentageBasis($pt);
    $self->originY($pt / 2);
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->rawHeight($pt);
};

# 'imperial', 'metric';
has 'unitType' => (is => 'rw', default => 'imperial');

# 'color', 'grayscale', 'black'
has 'colorType' => (is => 'rw', default => 'color');

# 'seyes', etc.
has 'rulingName' => (is => 'rw');

has 'leftMarginX' => (is => 'rw');              # in pt, left = 0
has 'rightMarginX' => (is => 'rw');             # in pt, left = 0
has 'topMarginY' => (is => 'rw');               # in pt, top = 0
has 'bottomMarginY' => (is => 'rw');            # in pt, top = 0

# My::Printable::Unit
has 'unit' => (is => 'rw');
has 'unitX' => (is => 'rw');
has 'unitY' => (is => 'rw');

has 'modifiers' => (
    is => 'rw',
    default => sub { return My::Printable::ModifierList->new(); },
);
has 'elements' => (
    is => 'rw',
    default => sub { return []; },         # via appendElement
);
has 'elementsById' => (
    is => 'rw',
    default => sub { return {}; },         # via appendElement
);

has 'originX' => (is => 'rw');
has 'originY' => (is => 'rw');

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
has 'verbose'     => (is => 'rw', default => 0);
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
    $self->svgDefs;
    $self->svgStyle;
    $self->svgAdditionalStyle;
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
        return $self->addStyleElement($self->defaultStyles);
    },
    clearer => 'deleteSVGStyle',
);

has 'svgAdditionalStyle' => (
    is => 'rw',
    lazy => 1, builder => sub {
        my ($self) = @_;
        if (!defined $self->additionalStyles) {
            return;
        }
        return $self->addStyleElement($self->doubleCurly($self->additionalStyles));
    },
    clearer => 'deleteSVGAdditionalStyle',
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

sub addStyleElement {
    my ($self, $cssText) = @_;
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
use My::Printable::Util qw(round3);
use My::Printable::Unit;
use My::Printable::PaperSizes;

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
    $self->unit(My::Printable::Unit->new());
    $self->unitX(My::Printable::Unit->new());
    $self->unitY(My::Printable::Unit->new());
    $self->unitX->size($self->width);
    $self->unitY->size($self->height);
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
    my $text_style = 'font-family: "Courier", "Courier New", monospace; font-size: 6pt;';
    my $text_color =
        $self->colorType eq 'color'     ? '#b3b3ff' :
        $self->colorType eq 'grayscale' ? '#b3b3b3' :
        '#808080';
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
    $self->printToHandle(\*STDOUT);
};

use File::Basename qw(dirname);
use File::Path qw(make_path);

sub printToFile {
    my ($self, $filename) = @_;
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
    my $sqpt_size = My::Printable::PaperSizes->get_square_points($size);
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

    my $style = <<"EOF";
        .line, .dot { stroke-linecap: round; }
        .stroke-linecap-butt { stroke-linecap: butt; }

        .rectangle { fill: #ffffff; }

        .line.xx-thin    { stroke-width: {{ 2.667/600 in }}; }
        .line.x-thin     { stroke-width: {{ 4/600 in }}; }
        .line.thin       { stroke-width: {{ 5.333/600 in }}; }
        .line.semi-thin  { stroke-width: {{ 6.532/600 in }}; }
        .line            { stroke-width: {{ 8/600 in }}; }
        .line.semi-thick { stroke-width: {{ 9.798/600 in }}; }
        .line.thick      { stroke-width: {{ 12/600 in }}; }

        .dot.xx-thin     { stroke-width: {{ 2.667/300 in }}; }
        .dot.x-thin      { stroke-width: {{ 4/300 in }}; }
        .dot.thin        { stroke-width: {{ 5.333/300 in }}; }
        .dot.semi-thin   { stroke-width: {{ 6.532/300 in }}; }
        .dot             { stroke-width: {{ 8/300 in }}; }
        .dot.semi-thick  { stroke-width: {{ 9.798/300 in }}; }
        .dot.thick       { stroke-width: {{ 12/300 in }}; }

        .stroke-1     { stroke-width: {{  1/600 in }}; stroke-linecap: round; }
        .stroke-2     { stroke-width: {{  2/600 in }}; stroke-linecap: round; }
        .stroke-3     { stroke-width: {{  3/600 in }}; stroke-linecap: round; }
        .stroke-4     { stroke-width: {{  4/600 in }}; stroke-linecap: round; }
        .stroke-5     { stroke-width: {{  5/600 in }}; stroke-linecap: round; }
        .stroke-6     { stroke-width: {{  6/600 in }}; stroke-linecap: round; }
        .stroke-7     { stroke-width: {{  7/600 in }}; stroke-linecap: round; }
        .stroke-8     { stroke-width: {{  8/600 in }}; stroke-linecap: round; }
        .stroke-9     { stroke-width: {{  9/600 in }}; stroke-linecap: round; }
        .stroke-10    { stroke-width: {{ 10/600 in }}; stroke-linecap: round; }

        .blue  { stroke: #b3b3ff; }
        .red   { stroke: #ff9999; }
        .green { stroke: #b3ffb3; }
        .gray  { stroke: #b3b3b3; }

        .black         { stroke: #000000; }
        .half-black    { stroke: #808080; }
        .quarter-black { stroke: #c0c0c0; }

        .light.blue  { stroke: #d9d9ff; }
        .light.red   { stroke: #ffcccc; }
        .light.green { stroke: #d9ffd9; }
        .light.gray  { stroke: #d9d9d9; }

        .dark.blue  { stroke: #6767ff; }
        .dark.red   { stroke: #ff3333; }
        .dark.green { stroke: #67ff67; }
        .dark.gray  { stroke: #676767; }

        .alternate-blue  { stroke: #6767ff; opacity: 0.5; }
        .alternate-red   { stroke: #ff3333; opacity: 0.5; }
        .alternate-green { stroke: #67ff67; opacity: 0.5; }
        .alternate-gray  { stroke: #676767; opacity: 0.5; }

        .gray20 { stroke: #333333; }
        .gray40 { stroke: #666666; }
        .gray60 { stroke: #999999; }
        .gray80 { stroke: #cccccc; }
EOF

    $style = $self->doubleCurly($style);

    return $style;
}

# {{ 1/600 in }} => 0.12pt
sub doubleCurly {
    my ($self, $text) = @_;
    if (!defined $text) {
        if (scalar @_ >= 2) {
            return undef;
        }
        return;
    }
    $text =~ s{\{\{\s*(.*?)\s*\}\}}{$self->unit->pt($1) . 'px'}gxe;
    return $text;
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
