package My::Printable::Color;
use warnings;
use strict;
use v5.10.0;

use Moo;

use Exporter 'import';
our %EXPORT_TAGS = (
    const => [qw(COLOR_RED
                 COLOR_GREEN
                 COLOR_BLUE
                 COLOR_GRAY
                 COLOR_BLACK)],
);
our @EXPORT_OK = (
    @{$EXPORT_TAGS{const}},
);
our @EXPORT = ();

use List::Util qw(min max);

use constant COLOR_BLUE    => '#b3b3ff';
use constant COLOR_GREEN   => '#5aff5a';
use constant COLOR_RED     => '#ff9e9e';
use constant COLOR_GRAY    => '#bbbbbb';
use constant COLOR_ORANGE  => '#ffab57';
use constant COLOR_MAGENTA => '#ff8cff';
use constant COLOR_CYAN    => '#1cffff';
use constant COLOR_YELLOW  => '#ffff00'; # higher luminance
use constant COLOR_BLACK   => '#000000';

use constant COLOR_NON_REPRO_BLUE => '#95c9d7';

has 'r' => (is => 'rw', default => 1);
has 'g' => (is => 'rw', default => 1);
has 'b' => (is => 'rw', default => 1);
has 'a' => (is => 'rw', default => 1);
has '_stringValue' => (is => 'rw');

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    if (scalar @args == 1) {
        return $class->$orig(
            _stringValue => $args[0],
        );
    }
    return $class->$orig(@args);
};

sub BUILD {
    my ($self, $args) = @_;
    my $value = delete $args->{_stringValue};
    if (defined $value) {
        $self->parse($value);
    }
}

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

sub parse {
    my ($self, $value) = @_;

    # 3 or 4 hex digits
    if ($value =~ m{\A\#
                    ([[:xdigit:]])
                    ([[:xdigit:]])
                    ([[:xdigit:]])
                    ([[:xdigit:]])?
                    \z}xi) {
        my ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $self->r(hex($r) / 15);
        $self->g(hex($g) / 15);
        $self->b(hex($b) / 15);
        $self->a(hex($a // 'f') / 15);
        return;
    }

    # 6 or 8 hex digits
    if ($value =~ m{\A\#
                    ([[:xdigit:]]{2})
                    ([[:xdigit:]]{2})
                    ([[:xdigit:]]{2})
                    ([[:xdigit:]]{2})?
                    \z}xi) {
        my ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $self->r(hex($r) / 255);
        $self->g(hex($g) / 255);
        $self->b(hex($b) / 255);
        $self->a(hex($a // 'ff') / 255);
        return;
    }

    # 12 or 16 hex digits
    if ($value =~ m{\A\#
                    ([[:xdigit:]]{4})
                    ([[:xdigit:]]{4})
                    ([[:xdigit:]]{4})
                    ([[:xdigit:]]{4})?
                    \z}xi) {
        my ($r, $g, $b, $a) = ($1, $2, $3, $4);
        $self->r(hex($r) / 65535);
        $self->g(hex($g) / 65535);
        $self->b(hex($b) / 65535);
        $self->a(hex($a // 'ffff') / 65535);
        return;
    }

    my $rx_int_or_pct = qr{(?:
                               \d+(?:\.\d*)?
                           |
                               \.\d+
                           )%?}xi;

    if ($value =~ m{\A
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
        my ($r, $g, $b, $a) = ($1, $2, $3, $4);
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
        $self->r($r);
        $self->g($g);
        $self->b($b);
        $self->a($a // 1.0);
        return;
    }

    return $self->parse(COLOR_BLACK)   if $value eq 'black';
    return $self->parse(COLOR_RED)     if $value eq 'red';
    return $self->parse(COLOR_GREEN)   if $value eq 'green';
    return $self->parse(COLOR_BLUE)    if $value eq 'blue';
    return $self->parse(COLOR_GRAY)    if $value eq 'gray' || $value eq 'grey';
    return $self->parse(COLOR_YELLOW)  if $value eq 'yellow';
    return $self->parse(COLOR_ORANGE)  if $value eq 'orange';
    return $self->parse(COLOR_MAGENTA) if $value eq 'magenta';
    return $self->parse(COLOR_CYAN)    if $value eq 'cyan';
    return $self->parse(COLOR_NON_REPRO_BLUE) if $value eq 'non-repro-blue';
    return $self->parse(COLOR_NON_REPRO_BLUE) if $value eq 'non-photo-blue';

    die("invalid color $value\n");
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
