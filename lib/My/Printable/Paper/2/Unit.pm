package My::Printable::Paper::2::Unit;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Const qw(:unit);

use List::Util qw(any);

sub parse {
    my $unit = shift;
    my $axis = shift;
    my $paper = shift;

    return 1  if !defined $unit || $unit eq '';
    return 1  if any { $_ eq $unit } qw(pt pts point points);
    return IN if any { $_ eq $unit } (qw(in ins inch inches), "\"");
    return FT if any { $_ eq $unit } (qw(ft fts foot feet), "\'");
    return PC if any { $_ eq $unit } qw(pc pcs pica picas);
    return MM if any { $_ eq $unit } qw(mm mms
                                        millimeter millimeters
                                        millimetre millimetres);
    return CM if any { $_ eq $unit } qw(cm cms
                                        centimeter centimeters
                                        centimetre centimetres);
    return PX if any { $_ eq $unit } qw(px pxs pixel pixels);

    if (any { $_ eq $unit } qw(pd pds dot dots)) {
        if (!defined $paper) {
            die("cannot use $unit unit without paper object");
        }
        return 72 / $paper->dpi;
    }
    if (any { $_ eq $unit } qw(grid grids unit units)) {
        if (!defined $paper) {
            die("cannot use $unit unit without paper object");
        }
        if (!defined $axis) {
            die("axis not specified for '$unit' unit");
        }
        if ($axis eq 'x') {
            return $paper->parseCoordinate($paper->gridSpacingX, 'x');
        }
        if ($axis eq 'y') {
            return $paper->parseCoordinate($paper->gridSpacingY, 'y');
        }
        die("axis must be 'x' or 'y' for '$unit' unit");
    }
    if (any { $_ eq $unit } qw(% pct percent)) {
        if (!defined $paper) {
            die("cannot use $unit unit without paper object")
        }
        if (!defined $axis) {
            die("axis not specified for '$unit' unit");
        }
        if ($axis eq 'x') {
            return 0.01 * $paper->parseCoordinate($paper->width, 'x');
        }
        if ($axis eq 'y') {
            return 0.01 * $paper->parseCoordinate($paper->height, 'y');
        }
        die("axis must be 'x' or 'y' for '$unit' unit");
    }
    die("invalid unit: '$unit'");
}

1;
