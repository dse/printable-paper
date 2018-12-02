package My::Printable::Document;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::ModifierList;

public 'id';
public 'filename';

# 'letter', 'A4', etc.
public "paperSizeName",
    default => "letter",
    set => sub {
        my ($self, $spec) = @_;
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
        return $name;
    },
    raw_accessor_name => "rawPaperSizeName";

# in pt
public "width",
    default => 612,
    set => sub {
        my ($self, $value) = @_;
        my ($pt, $unit_type) = $self->pt($value);
        $self->unitType($unit_type);
        $self->rawPaperSizeName(undef);
        $self->unitX->setPercentageBasis($pt);
        $self->originX($pt / 2);
        $self->setLeftMargin(0);
        $self->setRightMargin(0);
        return $pt;
    },
    raw_accessor_name => "rawWidth";

# in pt
public "height",
    default => 792,
    set => sub {
        my ($self, $value) = @_;
        my ($pt, $unit_type) = $self->pt($value);
        $self->unitType($unit_type);
        $self->rawHeight($pt);
        $self->rawPaperSizeName(undef);
        $self->unitY->setPercentageBasis($pt);
        $self->originY($pt / 2);
        $self->setBottomMargin(0);
        $self->setTopMargin(0);
        return $pt;
    },
    raw_accessor_name => "rawHeight";

# 'imperial', 'metric';
public "unitType", default => "imperial";

# 'color', 'grayscale', 'black'
public "colorType", default => "color";

# 'seyes', etc.
public "rulingName";

public "leftMarginX";                          # in pt, left = 0
public "rightMarginX";                         # in pt, left = 0
public "topMarginY";                           # in pt, top = 0
public "bottomMarginY";                        # in pt, top = 0

# My::Printable::Unit
public "unit";
public "unitX";
public "unitY";

public "modifiers", builder => sub { return new My::Printable::ModifierList; };

public "elements",      builder => sub { return []; };         # via appendElement
public "elementsById",  builder => sub { return {}; };         # via appendElement

public "originX", set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public "originY", set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

public "isGenerated",   default => 0;
public "verbose",       default => 0;

use XML::LibXML;
use Scalar::Util qw(refaddr);

public "svgDocument", lazy_default => sub {
    my ($self) = @_;
    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
    return $doc;
}, delete => "deleteSVGDocument";

public "svgRoot", lazy_default => sub {
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
}, after_builder => sub {
    my ($self) = @_;
    $self->svgDefs;
    $self->svgStyle;
}, delete => "deleteSVGRoot";

public 'svgDefs', lazy => 1, builder => sub {
    my ($self) = @_;
    my $doc = $self->svgDocument;
    my $root = $self->svgRoot;
    my $defs = $doc->createElement('defs');
    $root->appendChild($defs);
    return $defs;
}, delete => 'deleteSVGDefs';

public 'svgStyle', lazy => 1, builder => sub {
    my ($self) = @_;
    my $doc = $self->svgDocument;
    my $root = $self->svgRoot;
    my $style = $doc->createElement('style');
    $style->appendText($self->defaultStyles);
    $root->appendChild($style);
    return $style;
}, delete => 'deleteSVGStyle';

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
    $self->deleteSVGDefs();
    $self->deleteSVGRoot();
    $self->deleteSVGDocument();
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

sub init {
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
        $self->colorType eq 'color' ? '#b3b3ff' :
        $self->colorType eq 'grayscale' ? '#b3b3b3' :
        '#808080';
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
        $rect->setAttribute('stroke', $text_color);
        $rect->setAttribute('stroke-width', $self->pt('2/600in'));
        $rect->setAttribute('fill', '#ffffff');
        $rect->setAttribute('rx', '2pt');
        $rect->setAttribute('ry', '2pt');
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

    my $xx_thin_line_stroke_width    = $self->unit->pt("2/600in");
    my $x_thin_line_stroke_width     = $self->unit->pt("3/600in");
    my $thin_line_stroke_width       = $self->unit->pt("4/600in");
    my $semi_thin_line_stroke_width  = $self->unit->pt("4.9/600in");
    my $line_stroke_width            = $self->unit->pt("6/600in");
    my $semi_thick_line_stroke_width = $self->unit->pt("7.35/600in");
    my $thick_line_stroke_width      = $self->unit->pt("9/600in");

    my $thin_dot_stroke_width        = $self->unit->pt("4/300in");
    my $semi_thin_dot_stroke_width   = $self->unit->pt("4.9/300in");
    my $dot_stroke_width             = $self->unit->pt("6/300in");
    my $semi_thick_dot_stroke_width  = $self->unit->pt("7.35/300in");
    my $thick_dot_stroke_width       = $self->unit->pt("9/300in");

    my $style = <<"EOF";
        .line, .dot { stroke-linecap: round; }
        .stroke-linecap-butt { stroke-linecap: butt; }

        .rectangle { fill: #ffffff; }

        .line            { stroke-width: ${line_stroke_width}pt; }
        .line.xx-thin    { stroke-width: ${xx_thin_line_stroke_width}pt; }
        .line.x-thin     { stroke-width: ${x_thin_line_stroke_width}pt; }
        .line.thin       { stroke-width: ${thin_line_stroke_width}pt; }
        .line.thick      { stroke-width: ${thick_line_stroke_width}pt; }
        .line.semi-thin  { stroke-width: ${semi_thin_line_stroke_width}pt; }
        .line.semi-thick { stroke-width: ${semi_thick_line_stroke_width}pt; }

        .dot             { stroke-width: ${dot_stroke_width}pt; }
        .dot.thin        { stroke-width: ${thin_dot_stroke_width}pt; }
        .dot.thick       { stroke-width: ${thick_dot_stroke_width}pt; }
        .dot.semi-thin   { stroke-width: ${semi_thin_dot_stroke_width}pt; }
        .dot.semi-thick  { stroke-width: ${semi_thick_dot_stroke_width}pt; }

        .stroke-1     { stroke-width: 0.12pt; stroke-linecap: round; } /* 1/600 in */
        .stroke-2     { stroke-width: 0.24pt; stroke-linecap: round; }
        .stroke-3     { stroke-width: 0.36pt; stroke-linecap: round; }
        .stroke-4     { stroke-width: 0.48pt; stroke-linecap: round; }
        .stroke-5     { stroke-width: 0.60pt; stroke-linecap: round; }
        .stroke-6     { stroke-width: 0.72pt; stroke-linecap: round; }
        .stroke-7     { stroke-width: 0.84pt; stroke-linecap: round; }
        .stroke-8     { stroke-width: 0.96pt; stroke-linecap: round; }
        .stroke-9     { stroke-width: 1.08pt; stroke-linecap: round; }
        .stroke-10    { stroke-width: 1.20pt; stroke-linecap: round; }

        .blue  { stroke: #b3b3ff; }
        .red   { stroke: #ff9999; }
        .green { stroke: #b3ffb3; }
        .gray  { stroke: #b3b3b3; }

/* begin enable if black */
        .black         { stroke: #000000; }
        .half-black    { stroke: #808080; }
        .quarter-black { stroke: #c0c0c0; }

/* end enable if black */
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
EOF

    if ($self->colorType eq 'black') {
        $style =~ s{^\s*
                    \Q/* begin enable if black */\E
                    [\ \t]*\R?}{}msxg;
        $style =~ s{^\s*
                    \Q/* end enable if black */\E
                    [\ \t]*\R?}{}msxg;
    } else {
        $style =~ s{^\s*
                    \Q/* begin enable if black */\E
                    .*?
                    \Q/* end enable if black */\E
                    [\ \t]*\R?}{}msxg;
    }
    return $style;
}

1;
