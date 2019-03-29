package My::Printable::Paper::Dimension;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Unit qw(:const);
use My::Printable::Paper::Regexp qw(:regexp);

use Moo;

has number   => (is => 'rw', default => 0);
has unit     => (is => 'rw', default => 'pt');
has document => (is => 'rw');
has axis     => (is => 'rw');

sub setFrom {
    my ($self, $from) = @_;
    foreach my $prop (qw(number unit document axis)) {
        $self->$prop($from->$prop);
    }
}

use Scalar::Util qw(blessed);

# ::Dimension->new();
# ::Dimension->new('18pt');
# ::Dimension->new('18pt', axis => 'x');
# ::Dimension->new([18, 'pt']);
# ::Dimension->new([18, 'pt'], axis => 'x');
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if (scalar @_ % 2 == 1) {
        # first argument is like '18pt' or ['18', 'pt']
        my $value = shift;
        my $hash = $class->$orig(@_);
        # set number to an arrayref; BUILD method will
        # parse at end of object creation.
        if (ref $value eq 'ARRAY') {
            $hash->{number} //= $value;
        } else {
            $hash->{number} //= [$value];
        }
        return $hash;
    } else {
        if ($_[0] =~ m{^${RE_NUMBER}$} && $_[1] =~ m{^${RE_UNIT}$}) {
            # first two arguments are a number and a unit
            my $number = shift;
            my $unit = shift;
            my $hash = $class->$orig(@_);
            $hash->{number} //= $number;
            $hash->{unit} //= $unit;
            return $hash;
        } else {
            return $class->$orig(@_);
        }
    }
};

use Data::Dumper qw(Dumper);

sub BUILD {
    my ($self, $args) = @_;
    if (ref $self->number eq 'ARRAY') {
        my ($number, $unit) = $self->parse($self->number);
        $self->number($number);
        $self->unit($unit);
    }
}

# __PACKAGE__->parse(...) or $dimension->parse(...) or parse(...);
#
# ...->parse([18]);
# ...->parse([18, 'pt']);
# ...->parse(18);
# ...->parse(18, 'pt');
sub parse {
    my $self = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
    my ($value, $unit);
    if (ref $_[0] eq 'ARRAY') {
        ($value, $unit) = @{$_[0]};
    } else {
        ($value, $unit) = @_;
    }
    $value //= 0;
    if ($value =~ m{^\s*
                    (${RE_NUMBER})\s*
                    (?:/\s*(${RE_NUMBER})\s*)?
                    (?:(${RE_UNIT})\s*)?
                    $}x) {
        my $number = $1 + 0;
        my $denom = ($2 // 1) + 0;
        $unit = $3 // $unit // 'pt';
        $number /= $denom;
        return ($number, $unit);
    }
    if (defined $unit) {
        die("invalid dimension: '$value $unit'");
    } else {
        die("invalid dimension: '$value'");
    }
}

sub set {
    my ($self, $value, $unit) = @_;
    if (eval { $value->isa(__PACKAGE__) }) {
        $self->setFrom($value);
        return;
    }
    (my $number, $unit) = $self->parse($value, $unit);
    $self->number($number);
    $self->unit($unit);
}

sub asPoints {
    my ($self) = @_;
    if (!defined $self->unit) {
        return $self->number;
    }
    if (grep { $self->unit eq $_ } qw(% pct percent)) {
        if (!defined $self->document) {
            die("document must be defined to use % unit");
        }
        if (!defined $self->axis && $self->axis ne 'x' && $self->axis ne 'y') {
            die("axis must be 'x' or 'y' to use % unit");
        }
        return $self->document->width  * $self->number / 100 if $self->axis eq 'x';
        return $self->document->height * $self->number / 100;
    }
    return $self->number * PT if grep { $self->unit eq $_ } qw(pt pts point points);
    return $self->number * PC if grep { $self->unit eq $_ } qw(pc pcs pica picas);
    return $self->number * IN if grep { $self->unit eq $_ } qw(in ins inch inches);
    return $self->number * CM if grep { $self->unit eq $_ } qw(cm cms centimeter centimeters centimetre centimetres);
    return $self->number * MM if grep { $self->unit eq $_ } qw(mm mms millimeter millimeters millimetre millimetres);
    return $self->number * PX if grep { $self->unit eq $_ } qw(px pxs pixel pixels);
    if (grep { $self->unit eq $_ } qw(pd pds dot dots)) {
        if (!defined $self->document) {
            die("document must be defined to use pd unit");
        }
        return $self->number * 72 / $self->document->dpi;
    }
    if (grep { $self->unit eq $_ } qw(tick ticks grid grids gridline gridlines line lines square squares unit units)) {
        if (!defined $self->document) {
            die("document must be defined to use tick unit");
        }
        if (!defined $self->axis) {
            die("axis must be defined to use tick unit");
        }
        return $self->number * $self->document->gridUnitX->asPoints if $self->axis eq 'x';
        return $self->number * $self->document->gridUnitY->asPoints;
    }
    die(sprintf("unit %s not defined", $self->unit));
}

1;
