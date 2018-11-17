package My::Printable::Util;
use warnings;
use strict;
use v5.10.0;

use base "Exporter";

our @EXPORT_OK = qw(exclude
                    round3
                    nearest_point);

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

use POSIX qw(ceil);

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::PointSeries;

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
