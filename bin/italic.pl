#!/usr/bin/env perl
use warnings;
use strict;
use open IO => ':locale';
use Math::Trig;
use POSIX qw(floor);

use FindBin;
use lib "${FindBin::Bin}/../lib";
use My::RuledPaper;
use My::RuledPaper::Constants qw(:all);
use My::RuledPaper::MonkeyPatch::Drawing;

my $paper = My::RuledPaper->new(width => 8.5*IN, height => 11*IN);
my $margin = 1/4*IN;

my $COLOR = "#ccccff";
my $major_width = 10/600*IN;
my $minor_width = 5/600*IN;
my $feint_width = 2/600*IN;

my $deg = 8;
my $dist = 1/20*IN;
my $major = 20;
my $minor = 5;

$paper->{style} = <<END;
    line, rect {
        fill: none;
        stroke-linecap: round;
        stroke-linejoin: round;
        stroke: ${COLOR};
    }
    .major {
        stroke-width: ${major_width}px;
    }
    .minor {
        stroke-width: ${minor_width}px;
    }
    .feint {
        stroke-width: ${feint_width}px;
    }
END

my $y_top = 1/4*IN;
my $y_bottom = $paper->{height} - 1/4*IN;
my $x_left = 1/4*IN;
my $x_right = $paper->{width} - 1/4*IN;

my $cx = ($x_left + $x_right) / 2;
my $cy = ($y_top + $y_bottom) / 2;

# vertical lines
$paper->line($x_left, $y_top, $x_left, $y_bottom, class => 'major');
$paper->line($x_right, $y_top, $x_right, $y_bottom, class => 'major');

# horizontal lines
$paper->line($x_left, $y_top, $x_right, $y_top, class => 'major');
$paper->line($x_left, $y_bottom, $x_right, $y_bottom, class => 'major');

my $atn = atan($deg * pi/180);

my $x0 = $x_left - $atn * ($y_bottom - $y_top);
my $x3 = $x_right + $atn * ($y_bottom - $y_top);

my $vert_line_count = floor(
    ($x_right - $cx + $atn * ($y_bottom - $cy)) / $dist
);

for (my $x = -$vert_line_count; $x <= $vert_line_count; $x += 1) {
    my $x1 = $cx  +  $x * $dist  +  $atn * ($cy - $y_top);
    my $x2 = $cx  +  $x * $dist  -  $atn * ($cy - $y_top);
    my $y1 = $y_top;
    my $y2 = $y_bottom;
    if ($x2 < $x_left) {
        $y2 = $y2 - ($x_left - $x2) / $atn;
        $x2 = $x_left;
    }
    if ($x1 > $x_right) {
        $y1 = $y1 + ($x1 - $x_right) / $atn;
        $x1 = $x_right;
    }
    $paper->line($x1, $y1, $x2, $y2, class => class($x));
}

my $horiz_line_count = floor(($y_bottom - $cy) / $dist);
for (my $y = -$horiz_line_count; $y <= $horiz_line_count; $y += 1) {
    my $y1 = $cy + $y * $dist;
    $paper->line($x_left, $y1, $x_right, $y1, class => class($y));
}

print($paper->svg());

sub class {
    my $n = shift;
    return ($n % $major == 0) ? 'major' : ($n % $minor == 0) ? 'minor' : 'feint';
}
