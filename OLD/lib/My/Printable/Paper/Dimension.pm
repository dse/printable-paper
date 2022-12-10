package My::Printable::Paper::Dimension;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Unit qw(:const);
use My::Printable::Paper::Regexp qw(:functions);

use Moo;

has number   => (is => 'rw', default => 0);
has unit     => (is => 'rw', default => 'pt'); # pt, in, mm, etc.
has document => (is => 'rw');
has axis     => (is => 'rw');   # x or y
has unitType => (is => 'rw', default => 'imperial'); # imperial or metric
has fromEdge => (is => 'rw');   # left, right, top, or bottom
has isNonNegative   => (is => 'rw', default => 0);

=head2 new

    my $dim = My::Printable::Paper::Dimension->new();
    my $dim = My::Printable::Paper::Dimension->new('18pt');
    my $dim = My::Printable::Paper::Dimension->new('18pt', axis => 'x', ...);
    my $dim = My::Printable::Paper::Dimension->new([18, 'pt']);
    my $dim = My::Printable::Paper::Dimension->new([18, 'pt'], axis => 'x', ...);

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if (scalar @_ % 2 == 1) {
        my $value = shift;
        my $hash = $class->$orig(@_);
        $hash->{number} = \$value; # BUILD will process
        return $hash;
    } else {
        my $value = shift . shift;
        my $hash = $class->$orig(@_);
        $hash->{number} = \$value;
        return $hash;
    }
};

use Data::Dumper qw(Dumper);
use Scalar::Util qw(blessed);

sub BUILD {
    my ($self, $args) = @_;
    my $value;
    if (ref $self->number eq 'SCALAR') {
        $value = ${$self->number};
    } elsif (ref $self->number eq 'ARRAY') {
        $value = join('', @{$self->number});
    }
    if (defined $value) {
        $self->set($value);
    }
}

=head2 parse

    my ($number, $unit, $unitType) = parse(18);
    my ($number, $unit, $unitType) = parse('18pt');
    my ($number, $unit, $unitType) = parse('18', 'pt');
    my ($number, $unit, $unitType) = parse(['18']);
    my ($number, $unit, $unitType) = parse(['18', 'pt']);

=cut

sub parse {
    my $self = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
    my $value;
    if (scalar @_ % 2 == 1) {
        $value = shift;
        $value = join('', @$value) if eval { ref $value eq 'ARRAY' };
    } else {
        $value = shift . shift;
    }
    my $match;
    if (!($match = matchDimension($value))) {
        die("invalid dimension: '$value'");
    }
    my $number   = ($match->{number2} // 0) + $match->{number} / ($match->{denominator} // 1);
    my $unit     = $match->{unit};
    my $fromEdge = $match->{fromEdge};
    my $unitType = $self->getUnitType($unit);
    return ($number, $unit, $fromEdge) if wantarray;
    return {
        number   => $number,
        unit     => $unit,
        fromEdge => $fromEdge,
    };
}

sub setFrom {
    my $self = shift;
    my $from = shift;
    foreach my $prop (qw(number unit document axis unitType fromEdge)) {
        $self->$prop($from->$prop);
    }
}

sub set {
    my $self = shift;
    if (eval { $_[0]->isa(__PACKAGE__) }) {
        $self->setFrom(shift);
        return;
    }
    my $result = $self->parse(@_);
    $self->number($result->{number});
    $self->unit($result->{unit});
    $self->fromEdge($result->{fromEdge});
    $self->unitType($result->{unitType});
}

use constant UNIT_PERCENT => qw(% pct percent);
use constant UNIT_PT      => qw(pt pts point points);
use constant UNIT_PC      => qw(pc pcs pica picas);
use constant UNIT_IN      => qw(in ins inch inches);
use constant UNIT_CM      => qw(cm cms centimeter centimeters centimetre centimetres);
use constant UNIT_MM      => qw(mm mms millimeter millimeters millimetre millimetres);
use constant UNIT_PX      => qw(px pxs pixel pixels);
use constant UNIT_PD      => qw(pd pds dot dots);
use constant UNIT_TICK    => qw(tick ticks grid grids gridline gridlines line lines square squares unit units);

sub asPoints {
    my ($self) = @_;
    my $number = $self->number;
    if ($self->isNonNegative) {
        $number = 0 if $number < 0;
    }
    if (!defined $self->unit) {
        return $number;
    }
    if (grep { $self->unit eq $_ } UNIT_PERCENT) {
        if (!defined $self->document) {
            die("document must be defined to use % unit");
        }
        if (!defined $self->axis && $self->axis ne 'x' && $self->axis ne 'y') {
            die("axis must be 'x' or 'y' to use % unit");
        }
        return $self->document->width  * $number / 100 if $self->axis eq 'x';
        return $self->document->height * $number / 100;
    }
    return $number * PT if grep { $self->unit eq $_ } UNIT_PT;
    return $number * PC if grep { $self->unit eq $_ } UNIT_PC;
    return $number * IN if grep { $self->unit eq $_ } UNIT_IN;
    return $number * CM if grep { $self->unit eq $_ } UNIT_CM;
    return $number * MM if grep { $self->unit eq $_ } UNIT_MM;
    return $number * PX if grep { $self->unit eq $_ } UNIT_PX;
    if (grep { $self->unit eq $_ } UNIT_PD) {
        if (!defined $self->document) {
            die("document must be defined to use pd unit");
        }
        return $number * 72 / $self->document->dpi;
    }
    if (grep { $self->unit eq $_ } UNIT_TICK) {
        if (!defined $self->document) {
            die("document must be defined to use tick unit");
        }
        if (!defined $self->axis) {
            die("axis must be defined to use tick unit");
        }
        return $number * $self->document->gridUnitX->asPoints if $self->axis eq 'x';
        return $number * $self->document->gridUnitY->asPoints;
    }
    die(sprintf("unit %s not defined", $self->unit));
}

sub asX { goto &asCoorindate; }
sub asY { goto &asCoorindate; }
sub asCoordinate {
    my ($self) = @_;
    die("asCoordinate: document must be specified") if !defined $self->document;
    die("asCoordinate: axis must be specified") if !defined $self->axis;
    if ($self->axis eq 'x') {
        if ($self->fromEdge eq 'right') {
            return $self->document->width - $self->asPoints;
        }
        return $self->asPoints;
    }
    if ($self->axis eq 'y') {
        if ($self->fromEdge eq 'bottom') {
            return $self->document->height - $self->asPoints;
        }
        return $self->asPoints;
    }
    die("asCoordinate: axis must be 'x' or 'y'");
}

sub getUnitType {
    my $self = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
    my $unit;
    if (blessed $self) {
        $unit = shift // $self->unit;
    } else {
        $unit = shift;
    }
    return if !defined $unit || $unit !~ m{\S};
    return            if grep { $unit eq $_ } UNIT_PERCENT;
    return 'imperial' if grep { $unit eq $_ } UNIT_PT;
    return 'imperial' if grep { $unit eq $_ } UNIT_PC;
    return 'imperial' if grep { $unit eq $_ } UNIT_IN;
    return 'metric'   if grep { $unit eq $_ } UNIT_CM;
    return 'metric'   if grep { $unit eq $_ } UNIT_MM;
    return 'imperial' if grep { $unit eq $_ } UNIT_PX;
    return            if grep { $unit eq $_ } UNIT_PD;
    return            if grep { $unit eq $_ } UNIT_TICK;
    return;
}

1;
