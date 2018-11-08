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
public "leftMargin";                           # in pt, from 0
public "rightMargin";                          # in pt, from 0
public "bottomMargin";                         # in pt, from 0
public "topMargin";                            # in pt, from 0
public "unit";                                 # My::Printable::Unit
public "unitX";                                # My::Printable::Unit
public "unitY";                                # My::Printable::Unit
public "modifiers",     default => [];         # arrayref
public "modifiersHash", default => {};         # hashref
public "elements",      default => [];
public "elementsById",  default => {};

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

sub init {
    my ($self) = @_;
    $self->unit(My::Printable::Unit->new());
    $self->unitX(My::Printable::Unit->new());
    $self->unitY(My::Printable::Unit->new());
}

sub start {
    my ($self) = @_;
    $self->svgDocument(undef);
    $self->svgRoot(undef);
    $self->layers(undef);
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
    $self->leftMargin($self->ptX($value));
}

sub setRightMargin {
    my ($self, $value) = @_;
    $self->rightMargin($self->width - $self->ptX($value));
}

sub setBottomMargin {
    my ($self, $value) = @_;
    $self->bottomMargin($self->ptY($value));
}

sub setTopMargin {
    my ($self, $value) = @_;
    $self->topMargin($self->height - $self->ptY($value));
}

sub setXOrigin {
    my ($self, $value) = @_;
    $self->xOrigin($self->ptX($value));
}

sub setYOrigin {
    my ($self, $value) = @_;
    $self->yOrigin($self->ptY($value));
}

sub generate {
    my ($self) = @_;
    $self->start();
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
    print $self->svgDocument->asString();
}

sub appendElement {
    my ($self, $element) = @_;

    if (grep { $_ eq $element } @{$self->elements}) {
        return;
    }

    my $id = $element->id;
    if (defined $id) {
        $self->elementsById->{$id} = $element;
    }
    push(@{$self->elements}, $element);

    $self->svgRoot->appendChild($element->svgLayer);
}

1;
