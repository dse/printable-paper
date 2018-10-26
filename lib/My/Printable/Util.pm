package My::Printable::Util;
use warnings;
use strict;
use v5.10.0;

use base "Exporter";

our @EXPORT_OK;
BEGIN {
    push(@EXPORT_OK, 'exclude', 'round3');
}

use Data::Dumper;

sub exclude(\@@);
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

1;
