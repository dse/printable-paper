package My::Printable::Paper::2::Const;
use warnings;
use strict;
use v5.10.0;

use base 'Exporter';
our %EXPORT_TAGS;
our @EXPORT;
our @EXPORT_OK;
BEGIN {
    %EXPORT_TAGS = (
        unit      => [qw(IN PT FT MM CM PX PC)],
        tolerance => [qw(TOLERANCE SVG_STROKE_DASH_TOLERANCE)],
    );
    @EXPORT = (
    );
    @EXPORT_OK = (
        (map { @$_ } values %EXPORT_TAGS),
    );
}

use constant IN => 72;
use constant PT => 1;
use constant FT => 72 * 12;
use constant MM => 72 / 25.4;
use constant CM => 72 / 2.54;
use constant PX => 72 / 96;
use constant PC => 12;

use constant TOLERANCE => 0.001;
use constant SVG_STROKE_DASH_TOLERANCE => 0.01; # in pt

1;
