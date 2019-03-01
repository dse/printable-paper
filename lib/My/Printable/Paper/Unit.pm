package My::Printable::Paper::Unit;
use warnings;
use strict;
use v5.10.0;

use Moo;

use Exporter 'import';
our %EXPORT_TAGS = (
    const => [qw(PT PC IN CM MM PX PD)],
);
our @EXPORT_OK = (
    @{$EXPORT_TAGS{const}}
);
our @EXPORT = ();

has units => (is => 'rw');
has axis => (is => 'rw');
has size => (is => 'rw');

use Storable qw(dclone);

use constant DEFAULT_DPI => 600; # per inch

use constant PT => 1;
use constant PC => 12;          # 1 pc = 12 pt
use constant IN => 72;          # 1 in = 72 pt
use constant CM => 72 / 2.54;   # ...
use constant MM => 72 / 25.4;
use constant PX => 72 / 96;
use constant PD => 72 / DEFAULT_DPI; # printer dots

our $UNITS = {
    "pt" => {
        to_pt => 1,
        type => "imperial",
    },
    "pc" => {
        to_pt => PC,
        type => "imperial",
    },
    "in" => {
        to_pt => IN,
        type => "imperial",
    },
    "cm" => {
        to_pt => CM,
        type => "metric",
    },
    "mm" => {
        to_pt => MM,
        type => "metric",
    },
    "px" => {
        to_pt => PX,
        type => "imperial"
    },
    "pd" => {
        to_pt => PD,
        type => "imperial"
    }
};

has dpi => (is => 'rw', default => DEFAULT_DPI, trigger => \&triggerDPI);

sub triggerDPI {
    my ($self, $dpi) = @_;
    $self->units->{pd}->{to_pt} = $self->units->{pt}->{to_pt} * IN / $dpi;
}

has defaultUnit => (is => 'rw', default => 'pt');

sub BUILD {
    my ($self) = @_;
    $self->units(dclone($UNITS));
}

sub set_percentage_basis {
    goto &setPercentageBasis;
}
sub setPercentageBasis {
    my ($self, $value) = @_;
    delete $self->units->{'%'};
    my $hash = $self->add_unit('%', $value);
    $self->size($hash->{to_pt});
    $hash->{to_pt} /= 100;
}

sub add_unit {
    goto &addUnit;
}
sub addUnit {
    my ($self, $unit, $value, %options) = @_;
    die("Unit already defined: $unit\n") if exists $self->units->{$unit};
    my ($pt, $unit_type) = $self->pt($value);

    my $aka = delete $options{aka};
    my @aka;
    if (defined $aka) {
        if (ref $aka eq "ARRAY") {
            @aka = @$aka;
        } elsif (ref $aka) {
            # do nothing
        } else {
            @aka = ($aka);
        }
    }
    foreach my $aka (@aka) {
        $self->units->{$aka} = $unit;
    }

    my $hash = {
        to_pt => $pt,
        type => $unit_type,
        %options
    };
    return $self->units->{$unit} = $hash;
}

sub delete_unit {
    goto &deleteUnit;
}
sub deleteUnit {
    my ($self, $unit) = @_;
    delete $self->units->{$unit};
}

sub rx_units {
    my ($self) = @_;
    $self = $self->REQUIRE_OBJECT();

    my @units = sort keys %{$self->units};
    @units = map {
        my $unit = $self->units->{$_};
        if (ref $unit eq "HASH" && $unit->{aka}) {
            if (ref $unit->{aka} eq "ARRAY") {
                ($_, @{$unit->{aka}});
            } elsif (ref $unit->{aka}) {
                ($_);
            } else {
                ($_, $unit->{aka});
            }
        } else {
            ($_);
        }
    } @units;
    my $units = join('|', map { quotemeta($_) } @units);
    return qr{$units}xi;
}

sub rx_number {
    my ($self) = @_;
    $self = $self->REQUIRE_OBJECT();
    return qr{[\-\+]?
              (?:\d+(?:\.\d*)?|\.\d+)
              (?:e[\-\+]?\d+)?}ix;
}

# $unit->qualifyValue('5.3mm',           'right') => ('5.3mm from right');
# $unit->qualifyValue('5.3mm from left', 'right') => ('5.3mm from right');
# $unit->qualifyValue('5.3mm from left', undef)   => ('5.3mm');
sub qualifyValue {
    my ($self, $value, $side) = @_;

    ($value, my $oldSide) = $self->splitValueSide($value);

    return $value if !defined $side;
    return $value . ' from ' . $side;
}

sub qualifyValueByDefault {
    my ($self, $value, $side) = @_;

    my $oldSide;
    ($value, $oldSide) = $self->splitValueSide($value);

    return $self->qualifyValue($value, $oldSide // $side);
}

# $unit->splitValueSide('5.3mm from right') => ('5.3mm', 'right');
sub splitValueSide {
    my ($self, $value) = @_;

    my $side;

    # ___ from {left,right,top,bottom,...}
    if ($value =~ s{\s+(?:from\s+)?
                    (left|right|top|bottom
                    |start|begin|beginning
                    |finish|end|ending)
                    \s*$}{}xi) {
        $side = lc($1);
    }

    # {left,right,top,bottom,...} ___
    if ($value =~ s{^\s*
                    (left|right|top|bottom
                    |start|begin|beginning
                    |finish|end|ending)
                    \s+}{}xi) {
        $side = lc($1);
    }

    return ($value, $side);
}

sub pt {
    my ($self, $value) = @_;
    $self = $self->REQUIRE_OBJECT();

    return undef if !defined $value;

    my ($numerator, $denominator);

    my $rx_units  = $self->rx_units;
    my $rx_number = $self->rx_number;
    my $spec;

    my $unit;
    if (ref $value eq "ARRAY") {
        ($value, $unit) = @$value;
    }

    my $is_from_end = 0;

    ($value, my $side) = $self->splitValueSide($value);
    if (defined $side) {
        if (grep { $_ eq $side } qw(right bottom finish end ending)) {
            $is_from_end = 1;
        }
    }

    if ($is_from_end && !defined $self->size) {
        die("Invalid use of 'right/bottom/finish/end/ending' prefix or 'from right/bottom/finish/end/ending' suffix.\n");
    }

    if (defined $unit && $unit ne "") {
        $spec = "$value $unit";
        if ($value =~ m{\A
                        \s*
                        ($rx_number)
                        (?:
                            \s*
                            /
                            \s*
                            ($rx_number)
                        )?
                        \s*
                        \z}xi) {
            ($numerator, $denominator) = ($1, $2);
        } else {
            die("Invalid size specification: $value $unit (error type 1)\n");
        }
    } else {
        $spec = "$value";
        if ($value =~ m{\A
                        \s*
                        ($rx_number)
                        (?:
                            \s*
                            /
                            \s*
                            ($rx_number)
                        )?
                        \s*
                        ($rx_units)?
                        \s*
                        \z}xi) {
            ($numerator, $denominator, $unit) = ($1, $2, $3);
        } else {
            die("Invalid size specification: $spec (error type 2)\n");
        }
    }

    my $number;
    if (defined $denominator) {
        $number = $numerator / $denominator;
    } else {
        $number = $numerator;
    }

    if (!defined $unit || $unit eq "") {

        my $defaultUnit = $self->defaultUnit;
        my $defaultUnitInfo = $self->units->{$defaultUnit};
        if (!defined $defaultUnitInfo) {
            die("defaultUnit of $defaultUnit does not exist\n");
        }
        my $defaultUnitToPt = $defaultUnitInfo->{to_pt};
        my $defaultUnitType = $defaultUnitInfo->{type};

        $number *= $defaultUnitToPt;
        return ($number, $defaultUnitType) if wantarray;
        return $number;

    }

    my $unit_info = $self->units->{$unit};
    while (defined $unit_info && !ref $unit_info) {
        $unit_info = $self->units->{$unit_info};
    }
    if (!defined $unit_info) {
        die("Invalid size specification: $spec [$unit] (error type 3)\n");
    }

    my $result_pt   = $number * $unit_info->{to_pt};
    my $result_type = $unit_info->{type};

    if ($is_from_end) {
        $result_pt = $self->size - $result_pt;
    }

    return ($result_pt, $result_type, $is_from_end) if wantarray;
    return $result_pt;
}

sub REQUIRE_OBJECT {
    my $self = shift;
    my $class = shift // __PACKAGE__;
    return $self if ref $self && $self->isa($class);
    state %singleton;
    return $singleton{$class} if exists $singleton{$class};
    return $singleton{$class} = $class->new();
}

1;
