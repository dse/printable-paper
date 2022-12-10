package My::RuledPaper::Constants;
use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(MM IN PT CM PC PX
                    A4_WIDTH_PX
                    A4_HEIGHT_PX
                    A5_WIDTH_PX
                    A5_HEIGHT_PX
                    LETTER_WIDTH_PX
                    LETTER_HEIGHT_PX
                    HALF_LETTER_WIDTH_PX
                    HALF_LETTER_HEIGHT_PX);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK]
);

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

1;
