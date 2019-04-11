package My::Printable::Paper::2::PaperSizeList;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::Const qw(:unit);
use My::Printable::Paper::2::Util qw(:snap);

use base 'Exporter';
our %EXPORT_TAGS;
our @EXPORT;
our @EXPORT_OK;
BEGIN {
    %EXPORT_TAGS = (
        functions => [qw(getPaperSizeByName)],
    );
    @EXPORT = (
    );
    @EXPORT_OK = (
        (map { @$_ } values %EXPORT_TAGS),
    );
}

our $PAPER_SIZES;
our %PAPER_SIZES;
BEGIN {
    $PAPER_SIZES = [

        # begin list of paper sizes listed in libpaper
        { name => 'letter',            width => 8.5 * IN,   height => 11 * IN   },
        { name => 'note',              width => 8.5 * IN,   height => 11 * IN   },
        { name => 'legal',             width => 8.5 * IN,   height => 14 * IN   },
        { name => 'executive',         width => 7.25 * IN,  height => 10.5 * IN },
        { name => 'halfletter',        width => 5.5 * IN,   height => 8.5 * IN  },
        { name => 'halfexecutive',     width => 5.25 * IN,  height => 7.25 * IN },
        { name => '11x17',             width => 11 * IN,    height => 17 * IN   },
        { name => 'statement',         width => 5.5 * IN,   height => 8.5 * IN  },
        { name => 'folio',             width => 8.5 * IN,   height => 13 * IN   },


        { name => 'quarto',            width => 215 * MM,   height => 275 * MM  }, # 610 x 780 pt listed in libpaper, or 8-15/32 x 10-13/16 in


        { name => '10x14',             width => 10 * IN,    height => 14 * IN   },
        { name => 'ledger',            width => 17 * IN,    height => 11 * IN   },
        { name => 'tabloid',           width => 11 * IN,    height => 17 * IN   },
        { name => 'Comm10',            width => 4.125 * IN, height => 9.5 * IN  }, # No. 10 envelope
        { name => 'Monarch',           width => 3.875 * IN, height => 7.5 * IN  }, # No. 7-3/4 "Monarch" envelope
        { name => 'archE',             width => 36 * IN,    height => 48 * IN   },
        { name => 'archD',             width => 24 * IN,    height => 36 * IN   },
        { name => 'archC',             width => 18 * IN,    height => 24 * IN   },
        { name => 'archB',             width => 12 * IN,    height => 18 * IN   },
        { name => 'archA',             width => 9 * IN,     height => 12 * IN   },
        { name => 'flsa',              width => 8.5 * IN,   height => 13 * IN   },
        { name => 'flse',              width => 8.5 * IN,   height => 13 * IN   },
        { name => 'csheet',            width => 17 * IN,    height => 22 * IN   },
        { name => 'dsheet',            width => 22 * IN,    height => 34 * IN   },
        { name => 'esheet',            width => 34 * IN,    height => 44 * IN   },
        { name => 'DL',                width => 110 * MM,   height => 220 * MM  }, # 312 x 624 pt listed in libpaper
        # end list of paper sizes listed in libpaper

        # my additions
        { name => 'travelersnotebook', width => 110 * MM,   height => 210 * MM  },
        { name => 'quarterletter',     width => 4.25 * IN,  height => 5.5 * IN  },
        { name => 'personalenvelope',  width => 3.625 * IN, height => 6.5 * IN  }, # No. 6-3/4 "personal" envelope

        # https://www.ibm.com/support/knowledgecenter/en/SSEPCD_9.5.0/com.ibm.ondemand.mp.doc/arsa0449.htm
        # https://www.supermap.com/EN/online/Objects%20Java%206R/ProgrammingReference/com/supermap/layout/PaperSize.html
        # https://docs.microsoft.com/en-us/windows/desktop/intl/paper-sizes
    ];

    # ISO A sizes -- 4a0, 2a0, a0 through a10
    foreach my $i (-2 .. 10) {
        my $sizeName = 'a' . $i;
        if ($i < 0) {
            $sizeName = (2 ** -$i) . 'a0';
        }
        my $width  = 1000 * 2 ** (-0.25 - $i / 2) * MM;
        my $height = 1000 * 2 ** (0.25 - $i / 2) * MM;
        push(@$PAPER_SIZES, {
            name => $sizeName, width => $width, height => $height
        });
    }

    # ISO B sizes
    foreach my $i (0 .. 10) {
        my $sizeName = 'b' . $i;
        my $width  = 1000 * 2 ** (0 - $i / 2) * MM;
        my $height = 1000 * 2 ** (0.5 - $i / 2) * MM;
        push(@$PAPER_SIZES, {
            name => $sizeName, width => $width, height => $height
        });
    }

    # ISO C sizes
    foreach my $i (0 .. 10) {
        my $sizeName = 'c' . $i;
        my $width  = 1000 * 2 ** (-0.125 - $i / 2) * MM;
        my $height = 1000 * 2 ** (0.375 - $i / 2) * MM;
        push(@$PAPER_SIZES, {
            name => $sizeName, width => $width, height => $height
        });
    }

    # JIS B sizes
    foreach my $i (0 .. 10) {
        my $sizeName = 'b' . $i . 'jis';
        my $width  = 1000 * 2 ** (0 - $i / 2)   * MM * sqrt(1.5 / sqrt(2));
        my $height = 1000 * 2 ** (0.5 - $i / 2) * MM * sqrt(1.5 / sqrt(2));
        push(@$PAPER_SIZES, {
            name => $sizeName, width => $width, height => $height
        });
    }

}

# populate %PAPER_SIZES
INIT {
    foreach my $size (@$PAPER_SIZES) {
        my $name = normalizeName($size->{name});
        $PAPER_SIZES{$name} = $size;
    }
}

# check for paper sizes too close together but not exactly the same
INIT {
    my $tolerance = 1;                 # in pt
    my $found = 0;
    foreach my $sizeA (@$PAPER_SIZES) {
        my $widthA = $sizeA->{width};
        my $heightA = $sizeA->{height};
        foreach my $sizeB (@$PAPER_SIZES) {
            my $widthB = $sizeB->{width};
            my $heightB = $sizeB->{height};
            if ($widthA == $widthB && $heightA == $heightB) {
                next;
            }
            if (snapeq($widthA, $widthB, $tolerance) &&
                    snapeq($heightA, $heightB, $tolerance)) {
                $found = 1;
                printf STDERR ("paper sizes %s and %s are too close " .
                                   "but not exactly equal.\n",
                               $sizeA->{name}, $sizeB->{name});
            }
        }
    }
    exit(1) if $found;
}

sub getPaperSizeByName {
    my ($name) = @_;
    $name = normalizeName($name);
    return $PAPER_SIZES{$name};
}

sub normalizeName {
    my ($name) = @_;
    $name = lc $name;
    $name =~ s{[^[:alnum:]]+}{}g;
    return $name;
}

sub getPaperSizeName {
    my ($width, $height) = @_;
    my $tolerance = 1;                 # in pt
    foreach my $size (@$PAPER_SIZES) {
        if (snapeq($size->{width}, $width, $tolerance) &&
                snapeq($size->{height}, $height, $tolerance)) {
            return $size;
        }
    }
}

1;
