package My::Printable::Util;
use warnings;
use strict;
use v5.10.0;

use base "Exporter";

our @EXPORT_OK = qw(exclude
                    round3
                    with_temp
                    linear_interpolate
                    USE_SVG_PATTERNS_FOR_DOT_GRIDS
                    USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND);

our %EXPORT_TAGS = (
    const => [qw(USE_SVG_PATTERNS_FOR_DOT_GRIDS
                 USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND)]
);

use constant USE_SVG_PATTERNS_FOR_DOT_GRIDS => 0;
use constant USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND => 0;

use Data::Dumper;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use Text::Trim;

sub exclude(\@@) {
    my ($a, @b) = @_;
    my %b = map { ($_, 1) } @b;
    return grep { !$b{$_} } @$a;
}

sub round3 {
    my ($value) = @_;
    if (!defined $value) {
        if (scalar @_) {
            return undef;
        }
        return;
    }
    $value = sprintf('%.3f', $value);
#    $value =~ s{(\.\d*?)0+$}{$1};
#    $value =~ s{\.$}{};
    return $value;
}

sub linear_interpolate {
    my ($v0, $v1, $t) = @_;
    return $v0 + $t * ($v1 - $v0);
}

sub with_temp {
    my ($filename, $sub) = @_;
    my $tempname = $filename;
    if ($filename =~ m{(?![^\.\\\/])(\.[^\.\/\\]+)$}x) {
        $tempname .= ".tmp" . $1;
    } else {
        $tempname .= ".tmp";
    }
    make_path(dirname($tempname));
    my $result;
    my @result;
    if (wantarray) {
        @result = $sub->($tempname);
    } elsif (defined wantarray) {
        $result = $sub->($tempname);
    } else {
        $sub->($tempname);
    }
    if (!rename($tempname, $filename)) {
        warn("cannot rename $tempname to $filename: $!\n");
    }
    return @result if wantarray;
    return $result if defined wantarray;
    return;
}

1;
