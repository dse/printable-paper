package My::RuledPaper::Sizes;
use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(%SIZES getPaperSize);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK],
);

use Sort::Naturally qw(nsort);

use lib "../..";
use My::RuledPaper::Constants qw(:units);

our %SIZES;
BEGIN {
    %SIZES = (
        a4              => [250 / 2**(1/4), 250 * 2**(1/4), MM],
        a5              => [125 * 2**(1/4), 250 / 2**(1/4), MM],
        letter          => [8.5, 11, IN],
        halfletter      => [5.5, 8.5, IN],
    );
}

foreach my $key (nsort keys %SIZES) {
    my $size = $SIZES{$key};
    if (defined $size->[2]) {
        $size->[0] *= $size->[2];
        $size->[1] *= $size->[2];
        delete $size->[2];
    }
}

sub getPaperSize {
    my ($sizeName) = @_;
    $sizeName = lc($sizeName);
    $sizeName =~ s{[^A-Za-z0-9]+}{}g;
    my $size = $SIZES{$sizeName};
    return if !defined $size;
    my $w = $size->[0] * $size->[2];
    my $h = $size->[1] * $size->[2];
    return ($w, $h) if wantarray;
    return [$w, $h];
}

1;
