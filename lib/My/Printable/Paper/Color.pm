package My::Printable::Paper::Color;
use warnings;
use strict;
use v5.10.0;

use Moo;

use Exporter 'import';
our %EXPORT_TAGS = (
    const => [qw(COLOR_BLUE
                 COLOR_GREEN
                 COLOR_RED
                 COLOR_GRAY
                 COLOR_ORANGE
                 COLOR_MAGENTA
                 COLOR_CYAN
                 COLOR_YELLOW
                 COLOR_BLACK
                 COLOR_NON_REPRO_BLUE)],
);
our @EXPORT_OK = (
    @{$EXPORT_TAGS{const}},
);
our @EXPORT = ();

use List::Util qw(min max);

use constant COLOR_BLUE           => '#b3b3ff';
use constant COLOR_GREEN          => '#5aff5a';
use constant COLOR_RED            => '#ff9e9e';
use constant COLOR_GRAY           => '#bbbbbb';
use constant COLOR_ORANGE         => '#ffab57';
use constant COLOR_MAGENTA        => '#ff8cff';
use constant COLOR_CYAN           => '#1cffff';
use constant COLOR_YELLOW         => '#ffff00'; # higher luminance
use constant COLOR_BLACK          => '#000000';
use constant COLOR_NON_REPRO_BLUE => '#95c9d7';

our %COLORS;
BEGIN {
    %COLORS = (
        'blue'           => COLOR_BLUE,
        'green'          => COLOR_GREEN,
        'red'            => COLOR_RED,
        'gray'           => COLOR_GRAY,
        'grey'           => COLOR_GRAY,
        'orange'         => COLOR_ORANGE,
        'magenta'        => COLOR_MAGENTA,
        'cyan'           => COLOR_CYAN,
        'yellow'         => COLOR_YELLOW,
        'black'          => COLOR_BLACK,
        'non-repro-blue' => COLOR_NON_REPRO_BLUE,
        'non-photo-blue' => COLOR_NON_REPRO_BLUE,
    );
}

sub aroundZeroToOne {
    my $orig = shift;
    my $self = shift;
    if (!scalar @_) {
        my $value = $self->$orig();
        if ($value < 0) {
            return $self->$orig(0);
        }
        if ($value > 1) {
            return $self->$orig(1);
        }
        return $value;
    }
    my $value = shift;
    if ($value < 0) {
        return $self->$orig(0);
    }
    if ($value > 1) {
        return $self->$orig(1);
    }
    return $self->$orig($value);
}

has r => (is => 'rw', default => 1);
has g => (is => 'rw', default => 1);
has b => (is => 'rw', default => 1);
has a => (is => 'rw', default => 1);

around r => \&aroundZeroToOne;
around g => \&aroundZeroToOne;
around b => \&aroundZeroToOne;
around a => \&aroundZeroToOne;

# so M::P::P::Color->new("#xxxxxx") or other one-argument forms can
# work.
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    if (scalar @args == 1) {
        if (eval { $args[0]->isa(__PACKAGE__) }) {
            return $args[0];
        }
        my ($r, $g, $b, $a) = $class->parse($args[0]);
        return $class->$orig(
            r => $r,
            g => $g,
            b => $b,
            a => $a,
        );
    }
    return $class->$orig(@args);
};

sub rgb {
    goto &rgba;
}

sub rgba {
    my ($self, $r, $g, $b, $a) = @_;
    $self->r($r);
    $self->g($g);
    $self->b($b);
    $self->a($a // 1);
}

sub set {
    my ($self, $value) = @_;
    my ($r, $g, $b, $a) = $self->parse($value);
    $self->r($r) if defined $r;
    $self->g($g) if defined $g;
    $self->b($b) if defined $b;
    $self->a($a) if defined $a;
}

sub parse {
    my ($self, $value) = @_;

    my $rx_int_or_pct = qr{(?:
                               \d+(?:\.\d*)?
                           |
                               \.\d+
                           )%?}xi;

    if (defined $COLORS{$value}) {
        $value = $COLORS{$value};
    }

    my ($r, $g, $b, $a);
    if ($value =~ m{\A\#
                    ([[:xdigit:]])
                    ([[:xdigit:]])
                    ([[:xdigit:]])
                    ([[:xdigit:]])?
                    \z}xi) {
        ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $r = hex($r) / 15;
        $g = hex($g) / 15;
        $b = hex($b) / 15;
        $a = hex($a // 'f') / 15;
    } elsif ($value =~ m{\A\#
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})
                         ([[:xdigit:]]{2})?
                         \z}xi) {
        ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $r = hex($r) / 255;
        $g = hex($g) / 255;
        $b = hex($b) / 255;
        $a = hex($a // 'ff') / 255;
    } elsif ($value =~ m{\A\#
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})
                         ([[:xdigit:]]{4})?
                         \z}xi) {
        ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $r = hex($r) / 65535;
        $g = hex($g) / 65535;
        $b = hex($b) / 65535;
        $a = hex($a // 'ffff') / 65535;
    } elsif ($value =~ m{\A
                         rgba?
                         \(
                         \s*
                         ($rx_int_or_pct)
                         (?:\s+|\s*,\s*)
                         ($rx_int_or_pct)
                         (?:\s+|\s*,\s*)
                         ($rx_int_or_pct)
                         (?:
                             (?:\s+|\s*,\s*)
                             ($rx_int_or_pct)
                         )?
                         \s*
                         \)
                         \z}xi) {
        ($r, $g, $b, $a) = ($1, $2, $3, $4);
        foreach ($r, $g, $b) {
            if (defined $_) {
                if (s{\%\z}{}) {
                    $_ /= 100;
                } else {
                    $_ /= 255;
                }
            }
        }
        foreach ($a) {
            if (defined $_ && s{\%\z}{}) {
                $_ /= 100;
            }
        }
        foreach ($r, $g, $b, $a) {
            if (defined $_) {
                if ($_ < 0) {
                    $_ = 0;
                } elsif ($_ > 1) {
                    $_ = 1;
                }
            }
        }
        $a //= 1.0;
    } else {
        die("invalid color $value\n");
    }
    return ($r, $g, $b, $a) if wantarray;
}

use POSIX qw(round);

sub asHex {
    my ($self) = @_;
    if ($self->a == 1) {
        return sprintf('#%02x%02x%02x',
                       round($self->r * 255),
                       round($self->g * 255),
                       round($self->b * 255));
    }
    return sprintf('#%02x%02x%02x%02x',
                   round($self->r * 255),
                   round($self->g * 255),
                   round($self->b * 255),
                   round($self->a * 255));
}

sub asRGB {
    my ($self) = @_;
    if ($self->a == 1) {
        return sprintf('rgb(%d, %d, %d)',
                       round($self->r * 255),
                       round($self->g * 255),
                       round($self->b * 255));
    }
    return sprintf('rgba(%d, %d, %d, %g)',
                   round($self->r * 255),
                   round($self->g * 255),
                   round($self->b * 255),
                   $self->a);
}

1;
