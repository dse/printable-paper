package My::Printable::Util;
use warnings;
use strict;
use v5.10.0;

use base "Exporter";

our @EXPORT_OK = qw(exclude
                    round3
                    linear_interpolate);

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

sub linear_interpolate {
    my ($v0, $v1, $t) = @_;
    return $v0 + $t * ($v1 - $v0);
}

1;
