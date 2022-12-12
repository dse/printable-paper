package My::RuledPaper::Constants;
use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(MM IN PT CM PC PX
                    A4
                    A5
                    LETTER
                    HALF_LETTER
                    A4_WIDTH_PX
                    A4_HEIGHT_PX
                    A5_WIDTH_PX
                    A5_HEIGHT_PX
                    LETTER_WIDTH_PX
                    LETTER_HEIGHT_PX
                    HALF_LETTER_WIDTH_PX
                    HALF_LETTER_HEIGHT_PX
                    COLOR_BLUE
                    COLOR_GREEN
                    COLOR_RED
                    COLOR_GRAY
                    COLOR_ORANGE
                    COLOR_MAGENTA
                    COLOR_CYAN
                    COLOR_YELLOW
                    COLOR_BLACK
                    COLOR_NON_REPRO_BLUE);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK]
);

# 96 / however many of each unit is in an inch
use constant MM => 96 / 25.4;
use constant IN => 96;
use constant PT => 96 / 72;
use constant CM => 96 / 2.54;
use constant PC => 96 / 6;
use constant PX => 1;

use constant A4_WIDTH_PX           => 250 / sqrt(sqrt(2)) * MM;
use constant A4_HEIGHT_PX          => 250 * sqrt(sqrt(2)) * MM;
use constant A5_WIDTH_PX           => 125 * sqrt(sqrt(2)) * MM;
use constant A5_HEIGHT_PX          => 250 / sqrt(sqrt(2)) * MM;
use constant LETTER_WIDTH_PX       => 8.5 * IN;
use constant LETTER_HEIGHT_PX      => 11 * IN;
use constant HALF_LETTER_WIDTH_PX  => 5.5 * IN;
use constant HALF_LETTER_HEIGHT_PX => 8.5 * IN;

use constant A4          => (width => A4_WIDTH_PX,          height => A4_HEIGHT_PX);
use constant A5          => (width => A5_WIDTH_PX,          height => A5_HEIGHT_PX);
use constant LETTER      => (width => LETTER_WIDTH_PX,      height => LETTER_HEIGHT_PX);
use constant HALF_LETTER => (width => HALF_LETTER_WIDTH_PX, height => HALF_LETTER_HEIGHT_PX);

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

1;
