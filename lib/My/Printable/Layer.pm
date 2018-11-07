package My::Printable::Layer;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;
use Class::Thingy::Delegate;

public "elements";
public "document";
public "id";

public "svgLayer", lazy_default => sub {
    my ($self) = @_;
    my $id = $self->id;
    die("id not defined before node called\n") if !defined $id;

    my $doc = $self->svgDocument;
    my $g = $doc->createElement("g");
    $g->setAttribute("id", $id);
    return $g;
};

delegate "unitX", via => "document";
delegate "unitY", via => "document";
delegate "unit",  via => "document";

delegate "svgDocument", via => "document";
delegate "svgRoot",     via => "document";

sub init {
    my ($self) = @_;
    $self->elements([]);
}

sub draw {
    my ($self) = @_;
    foreach my $element (@{$self->elements}) {
        $element->draw;
    }
}

1;
