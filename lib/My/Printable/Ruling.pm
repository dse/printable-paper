package My::Printable::Ruling;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;
use Class::Thingy::Delegate;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Document;

public 'document', builder => sub {
    return My::Printable::Document->new();
};

delegate 'id',            via => 'document';
delegate 'filename',      via => 'document';
delegate 'setPaperSize',  via => 'document';
delegate 'setWidth',      via => 'document';
delegate 'setHeight',     via => 'document';
delegate 'setModifiers',  via => 'document';
delegate 'hasModifier',   via => 'document';
delegate 'unitType',      via => 'document';
delegate 'colorType',     via => 'document';
delegate 'generate',      via => 'document';
delegate 'print',         via => 'document';
delegate 'isA4SizeClass', via => 'document';
delegate 'isA5SizeClass', via => 'document';

sub getUnit {
    my ($self) = @_;

    my $has_denser_grid = grep { $self->hasModifier->{$_} }
        qw(5-per-inch denser-grid 1/5in 5mm);

    if ($self->unitType eq 'imperial') {
        if ($has_denser_grid) {
            return '1/5in';
        } else {
            return '1/4in';
        }
    } else {
        if ($has_denser_grid) {
            return '5mm';
        } else {
            return '6mm';
        }
    }
}

sub getMarginLineCSSClass {
    my ($self) = @_;
    if ($self->colorType eq 'grayscale') {
        return 'gray margin line';
    } else {
        return 'red margin line';
    }
}

1;
