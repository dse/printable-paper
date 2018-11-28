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
}, delete => 'deleteDocument';

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
delegate 'printToFile',   via => 'document';
delegate 'isA4SizeClass', via => 'document';
delegate 'isA5SizeClass', via => 'document';

use constant rulingName => 'none';
use constant hasLineGrid => 0;
use constant lineGridThinness => 0;
use constant lineThinness => 0;
use constant dotThinness => 0;

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
    } elsif ($self->colorType eq 'color') {
        return 'red margin line';
    } else {
        return 'stroke-3 black line';
    }
}

sub getLineCSSClass {
    my ($self) = @_;

    my $thinness =
        $self->hasModifier->{'x-thinner-lines'} ? 2 :
        $self->hasModifier->{'thinner-lines'} ? 1 :
        0;                            # 0 to 2
    $thinness += $self->lineThinness; # 0 to 4

    my $thinness_class_A = [
        '',                     # regular
        'thin',
        'x-thin',
        'xx-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-3 black',
        'stroke-2 black',
        'stroke-1 black',
        'stroke-1 half-black',
        'stroke-1 quarter-black',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return "$thinness_class_A gray line";
    } elsif ($self->colorType eq 'color') {
        return "$thinness_class_A blue line";
    } else {
        return "$thinness_class_B line";
    }

    # regular for doane
    # thin/x-thin/xx-thin for line-dot-grid
    # x-thin for quadrille
    # regular for seyes
}

sub getFeintLineCSSClass {
    my ($self) = @_;

    my $thinness;
    if ($self->hasLineGrid) {
        $thinness =
            $self->hasModifier->{'x-thinner-grid'} ? 2 :
            $self->hasModifier->{'thinner-grid'} ? 1 :
            0;                  # 0 to 2
        $thinness +=
            $self->hasModifier->{'denser-grid'} ? 1 :
            0;                  # 0 to 3
        $thinness += $self->lineGridThinness; # 0 to 4
    } else {
        $thinness =
            $self->hasModifier->{'x-thinner-lines'} ? 2 :
            $self->hasModifier->{'thinner-lines'} ? 1 :
            0;                  # 0 to 2
    }

    my $thinness_class_A = [
        'thin',
        'x-thin',
        'xx-thin',
        'xx-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-1 black',
        'stroke-1 half-black',
        'stroke-1 quarter-black',
        'stroke-1 quarter-black',
        'stroke-1 quarter-black',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return "$thinness_class_A gray line";
    } elsif ($self->colorType eq 'color') {
        return "$thinness_class_A blue line";
    } else {
        return "$thinness_class_B line";
    }
}

sub getDotCSSClass {
    my ($self) = @_;

    my $thinness =
        $self->hasModifier->{'x-thinner-dots'} ? 2 :
        $self->hasModifier->{'thinner-dots'} ? 1 :
        0;                           # 0 to 2
    $thinness += $self->dotThinness; # -1 to 4
    $thinness += 1;                  # 0 to 5

    my $thinness_class_A = [
        'semi-thick',
        '',                     # regular
        'semi-thin',
        'thin',
        'x-thin',
        'xx-thin',
    ]->[$thinness];
    my $thinness_class_B = [
        'stroke-7 black',
        'stroke-5 black',
        'stroke-4 black',
        'stroke-3 black',
        'stroke-2 black',
        'stroke-1 black',
    ]->[$thinness];

    if ($self->colorType eq 'grayscale') {
        return "$thinness_class_A gray dot";
    } elsif ($self->colorType eq 'color') {
        return "$thinness_class_A blue dot";
    } else {
        return "$thinness_class_B dot";
    }

    # regular for dot-grid
    # thin for line-dot-graph
    # semi-thick/regular/semi-thin for line-dot-grid
}

sub getRulingClassName {
    my ($self, $name) = @_;
    my $class_suffix = $name;
    $class_suffix =~ s{(^|[-_]+)
                       ([[:alpha:]])}
                      {uc $2}gex;
    my $ruling_class_name = "My::Printable::Ruling::" . $class_suffix;
    return $ruling_class_name;
}

# margin line  line            feint line        dot
# -----------  --------------  ----------------  --------------
# stroke-3     stroke-3        stroke-1          stroke-7
# stroke-3     stroke-2        stroke-1 half     stroke-5
# stroke-3     stroke-1        stroke-1 quarter  stroke-4
# stroke-3     stroke-1 half   stroke-1 quarter  stroke-3

1;
