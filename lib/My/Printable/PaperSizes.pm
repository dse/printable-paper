package My::Printable::PaperSizes;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Unit;

use POSIX qw(round);

our $SIZES;
INIT {                          # cannot use BEGIN here.
    $SIZES = {
        letter => {
            width  => scalar(My::Printable::Unit->pt([8.5, "in"])),
            height => scalar(My::Printable::Unit->pt([11, "in"])),
            type   => "imperial",
        },
        a4 => {
            width  => scalar(My::Printable::Unit->pt([250 / sqrt(sqrt(2)), "mm"])),
            height => scalar(My::Printable::Unit->pt([250 * sqrt(sqrt(2)), "mm"])),
            type   => "metric",
        },
        halfletter => {
            width  => scalar(My::Printable::Unit->pt([5.5, "in"])),
            height => scalar(My::Printable::Unit->pt([8.5, "in"])),
            type   => "imperial",
        },
        a5 => {
            width  => scalar(My::Printable::Unit->pt([125 * sqrt(sqrt(2)), "mm"])),
            height => scalar(My::Printable::Unit->pt([250 / sqrt(sqrt(2)), "mm"])),
            type   => "metric",
        },
    };
}

sub parse {
    my ($self, $spec) = @_;
    $spec = lc $spec;

    my $result =
        $self->parse_builtin_papersize($spec) //
        $self->parse_custom_papersize($spec) //
        $self->parse_paperconf_papersize($spec);
    if (wantarray) {
        return ($result->{name},
                $result->{width},
                $result->{height},
                $result->{type});
    }
    return $result;
}

sub parse_builtin_papersize {
    my ($self, $spec) = @_;
    $spec = lc $spec;

    my $info = $SIZES->{spec};
    return if !$info;

    $info = { %$info };     # shallow copy
    $info->{name} //= $spec;
    return $info;
}

sub parse_paperconf_papersize {
    my ($self, $spec) = @_;
    $spec = lc $spec;

    my $ph;
    my @cmd;
    if (defined $spec) {
        @cmd = ("paperconf", "-p", $spec, "-n", "-s");
    } else {
        @cmd = ("paperconf", "-n", "-s");
    }
    if (!open($ph, "-|", @cmd)) {
        warn("exec paperconf: $!");
        return;
    }
    local $/ = undef;
    my $result = <$ph>;
    if (!close($ph)) {
        warn("paperconf failed: $!");
        return;
    }
    $result =~ s{\A\s+}{};
    $result =~ s{\s+\z}{};

    my ($name, $width, $height) = split(' ', $result);
    my $unit_type;
    if ($width == round($width) && $height == round($height)) {
        $unit_type = "imperial";
    } else {
        $unit_type = "metric";
    }

    return {
        name => $name,
        width => $width,
        height => $height,
        type   => $unit_type
    };
}

sub parse_custom_papersize {
    my ($self, $spec) = @_;
    $spec = lc $spec;

    my $rx_number = My::Printable::Unit->rx_number;
    my $rx_units  = My::Printable::Unit->rx_units;

    if ($spec =~ m{\A
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
                   (?:\*|x)
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
        my ($width, $width_denominator, $x_unit,
            $height, $height_denominator, $y_unit) = ($1, $2, $3, $4, $5, $6);

        $width  /= $width_denominator  if defined $width_denominator;
        $height /= $height_denominator if defined $height_denominator;

        if (!defined $y_unit || $y_unit eq "") {
            $y_unit = "pt";
        }
        if (!defined $x_unit || $x_unit eq "") {
            $x_unit = $y_unit;
        }

        my $x_type;
        my $y_type;
        ($width,  $x_type) = My::Printable::Unit->pt([$width,  $x_unit]);
        ($height, $y_type) = My::Printable::Unit->pt([$height, $y_unit]);

        my $unit_type = $x_type // $y_type;
        if (wantarray) {
            return (undef, $width, $height, $unit_type);
        }
        return {
            width  => $width,
            height => $height,
            type   => $unit_type
        };
    }
    return;
}

our %SQUARE_POINTS;

sub get_square_points {
    my ($self, $size) = @_;
    if (exists $SQUARE_POINTS{$size}) {
        return $SQUARE_POINTS{$size};
    }
    my $hash = My::Printable::PaperSizes->parse($size);
    if (!$hash) {
        return $SQUARE_POINTS{$size} = undef;
    }
    my $width  = $hash->{width};
    my $height = $hash->{height};
    if (!$width || !$height) {
        return $SQUARE_POINTS{$size} = 0;
    }
    return $SQUARE_POINTS{$size} = $width * $height;
}

our $SINGLETON;

sub object {
    my ($self) = @_;
    if (!ref $self) {
        $self = ($SINGLETON //= __PACKAGE__->new);
    }
    return $self;
}

1;
