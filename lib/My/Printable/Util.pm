package My::Printable::Util;
use warnings;
use strict;
use v5.10.0;

use base "Exporter";

our @EXPORT_OK = qw(exclude round3 get_point_series nearest_point);

use Data::Dumper;

sub exclude(\@@) {
    my ($a, @b) = @_;
    my %b = map { ($_, 1) } @b;
    return grep { !$b{$_} } @$a;
}

sub round3 {
    my ($value) = @_;
    $value = sprintf('%.3f', $value);
    $value =~ s{(\.\d*?)0+$}{$1};
    $value =~ s{\.$}{};
    return $value;
}

sub get_point_series {
    my %args = @_;
    my $spacing = delete $args{spacing};
    my $origin  = delete $args{origin};
    my $min     = delete $args{min};
    my $max     = delete $args{max};
    my $axis    = delete $args{axis}; # 'x' or 'y'

    $min -= 3 * $spacing;
    $max += 3 * $spacing;

    my @points = ($origin);
    my $x;

    # float
    for ($x = $origin + $spacing; $x <= $max; $x += $spacing) {
        push(@points, $x);
    }

    # float
    for ($x = $origin - $spacing; $x >= $min; $x -= $spacing) {
        unshift(@points, $x);
    }

    return @points if wantarray;
    return \@points;
}

sub nearest_point {
    my ($self, $x, @points) = @_;
    my @dist = map { abs($x - $_) } @points;
    my $mindist = min(@dist);
    for (my $i = 0; $i < scalar @points; $i += 1) {
        if ($mindist == $dist[$i]) {
            return $points[$i];
        }
    }
    return undef;               # should NEVER happen.
}

1;
