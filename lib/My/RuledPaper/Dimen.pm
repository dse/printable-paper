package My::RuledPaper::Dimen;
use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(parseDimen);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK],
);

use lib "../..";
use My::RuledPaper::Constants qw($RE_UNIT $RE_NUM %UNITS);

sub parseDimen {
    my ($str) = @_;
    if ($str =~ m{^(?<num>$RE_NUM) \s* (?<unit>$RE_UNIT)$}xi) {
        my $num = $+{num};
        my $unit = $+{unit};
        return $num * $UNITS{lc($unit)};
    }
    if ($str =~ m{^$RE_NUM$}) {
        return 0 + $str;
    }
}

1;
