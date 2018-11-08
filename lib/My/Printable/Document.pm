package My::Printable::Document;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

public "paperSizeName", default => "letter";   # letter, A4, etc.
public "width",         default => 612;        # in pt
public "height",        default => 792;        # in pt
public "unitType",      default => "imperial"; # imperial, metric
public "colorType",     default => "color";    # color, grayscale
public "rulingName";                           # seyes, etc.
public "leftMarginX";                          # in pt, from 0
public "rightMarginX";                         # in pt, from 0
public "bottomMarginY";                        # in pt, from 0
public "topMarginY";                           # in pt, from 0
public "unit";                                 # My::Printable::Unit
public "unitX";                                # My::Printable::Unit
public "unitY";                                # My::Printable::Unit
public "modifiers",     default => [];         # arrayref
public "modifiersHash", default => {};         # hashref
public "elements",      default => [];
public "elementsById",  default => {};

use XML::LibXML;

public "svgDocument", lazy_default => sub {
    my ($self) = @_;
    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
    return $doc;
};

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
    $root->appendChild($self->createSVGStyle);
    return $root;
};

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

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util qw(round3);
use My::Printable::Unit;

sub init {
    my ($self) = @_;
    $self->unit(My::Printable::Unit->new());
    $self->unitX(My::Printable::Unit->new());
    $self->unitY(My::Printable::Unit->new());
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
}

sub setPaperSize {
    my ($self, $spec) = @_;
    my ($name, $width, $height, $type) = My::Printable::PaperSizes->parse($spec);
    $self->unitType($type);
    $self->paperSizeName($name);
    $self->width($width);
    $self->height($height);
    $self->unitX->set_percentage_basis($width);
    $self->unitY->set_percentage_basis($height);
    $self->setXOrigin($width / 2);
    $self->setYOrigin($height / 2);
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
}

sub setWidth {
    my ($self, $value) = @_;
    my ($pt, $type) = $self->pt($value);
    $self->unit_type($type);
    $self->width($pt);
    $self->paperSizeName(undef);
    $self->unitX->set_percentage_basis($pt);
    $self->setXOrigin($pt / 2);
    $self->setLeftMargin(0);
    $self->setRightMargin(0);
}

sub setHeight {
    my ($self, $value) = @_;
    my ($pt, $type) = $self->pt($value);
    $self->unit_type($type);
    $self->height($pt);
    $self->papersize(undef);
    $self->unitY->set_percentage_basis($pt);
    $self->setYOrigin($pt / 2);
    $self->setBottomMargin(0);
    $self->setTopMargin(0);
}

sub setModifiers {
    my ($self, @modifiers) = @_;
    @modifiers = grep { defined $_ } @modifiers;
    my %modifiers = map { ($_, 1) } @modifiers;
    $self->modifiers(\@modifiers);
    $self->modifiersHash(\%modifiers);
}

sub setLeftMargin {
    my ($self, $value) = @_;
    $self->leftMarginX($self->ptX($value));
}

sub setRightMargin {
    my ($self, $value) = @_;
    $self->rightMarginX($self->width - $self->ptX($value));
}

sub setBottomMargin {
    my ($self, $value) = @_;
    $self->bottomMarginY($self->ptY($value));
}

sub setTopMargin {
    my ($self, $value) = @_;
    $self->topMarginY($self->height - $self->ptY($value));
}

sub setXOrigin {
    my ($self, $value) = @_;
    $self->xOrigin($self->ptX($value));
}

sub setYOrigin {
    my ($self, $value) = @_;
    $self->yOrigin($self->ptY($value));
}

sub setUnit {
    my ($self, $value) = @_;
    $self->unit->addUnit("unit", scalar($self->pt($value)));
    $self->unitX->addUnit("unit", scalar($self->ptX($value)));
    $self->unitY->addUnit("unit", scalar($self->ptY($value)));
}

sub generate {
    my ($self) = @_;
    $self->compute();
    $self->chop();
    $self->snap();
    $self->exclude();
    $self->draw();
}

sub compute {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->compute();
    }
}

sub chop {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->chop();
    }
}

sub snap {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->snap();
    }
}

sub exclude {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->exclude();
    }
}

sub draw {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->draw();
    }
}

sub print {
    my ($self) = @_;
    $self->generate();
    print $self->svgDocument->toString(2);
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

    $self->svgRoot->appendChild($element->svgLayer);
}

sub createSVGStyle {
    my ($self) = @_;
    my $style = $self->svgDocument->createElement('style');
    $style->appendText($self->defaultStyles);
    return $style;
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

    return <<"EOF";
    .line, .dot { stroke-linecap: round; }
    .stroke-linecap-butt { stroke-linecap: butt; }

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

    .blue  { stroke: #b3b3ff; }
    .red   { stroke: #ff9999; }
    .green { stroke: #b3ffb3; }
    .gray  { stroke: #b3b3b3; }

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
}

1;
