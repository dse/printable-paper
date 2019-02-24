package My::Printable::Paper::Util;
use warnings;
use strict;
use v5.10.0;

use Moo;

use Exporter 'import';
our %EXPORT_TAGS = (
    const => [qw(USE_SVG_PATTERNS_FOR_DOT_GRIDS
                 USE_SVG_DOTTED_LINES_FOR_DOT_GRIDS
                 USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND
                 FUDGE_FACTOR
                 SVG_DOTTED_LINE_FUDGE_FACTOR)],
    around => [qw(aroundUnit
                  aroundUnitX
                  aroundUnitY)],
);
our @EXPORT_OK = (
    qw(exclude
       round3
       with_temp
       withTemp
       linear_interpolate
       linearInterpolate
       snapcmp
       snapnum
       side_direction
       sideDirection
       strokeDashArray
       strokeDashOffset),
    @{$EXPORT_TAGS{const}},
    @{$EXPORT_TAGS{around}},
);
our @EXPORT = ();

use constant USE_SVG_PATTERNS_FOR_DOT_GRIDS => 0;
use constant USE_SVG_DOTTED_LINES_FOR_DOT_GRIDS => 1;
use constant USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND => 0;
use constant FUDGE_FACTOR => 0.0001;

# to work around an Inkscape PDF rendering bug.
use constant SVG_DOTTED_LINE_FUDGE_FACTOR => 0.01;

use Data::Dumper;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use Text::Trim;
use Scalar::Util qw(blessed);

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
    goto &linearInterpolate;
}
sub linearInterpolate {
    my ($v0, $v1, $t) = @_;
    return $v0 + $t * ($v1 - $v0);
}

sub with_temp {
    goto &withTemp;
}
sub withTemp {
    my ($filename, $sub) = @_;
    my $tempname = $filename;
    if ($filename =~ m{(?![^\.\\\/])(\.[^\.\/\\]+)$}x) {
        $tempname .= ".tmp" . $1;
    } else {
        $tempname .= ".tmp";
    }
    make_path(dirname($tempname));
    unlink($tempname);
    my $result = $sub->($tempname);
    if (!(defined $result && $result == -1)) {
        if (!rename($tempname, $filename)) {
            warn("cannot rename $tempname to $filename: $!\n");
        }
    }
    return $result;
}

sub aroundUnit {
    my $orig = shift;
    my $self = shift;
    if (!scalar @_) {
        return $self->$orig;
    }
    my $value = shift;
    if ($self->can('pt')) {
        $value = $self->pt($value);
    } else {
        $value = My::Printable::Paper::Unit->pt($value);
    }
    $self->$orig($value, @_);
}

sub aroundUnitX {
    my $orig = shift;
    my $self = shift;
    if (!scalar @_) {
        return $self->$orig;
    }
    my $value = shift;
    $value = $self->ptX($value);
    $self->$orig($value, @_);
}

sub aroundUnitY {
    my $orig = shift;
    my $self = shift;
    if (!scalar @_) {
        return $self->$orig;
    }
    my $value = shift;
    $value = $self->ptY($value);
    $self->$orig($value, @_);
}

sub snapcmp {
    my ($a, $b, $fudge) = @_;
    $fudge //= FUDGE_FACTOR;
    return 0 if (abs($a - $b) < $fudge);
    return $a - $b;
}

sub snapnum {
    my ($a, $fudge) = @_;
    $fudge //= FUDGE_FACTOR;
    return 0 if abs($a) < $fudge;
    return $a;
}

sub side_direction {
    goto &sideDirection;
}
sub sideDirection {
    my ($side) = @_;
    return 'horizontal' if $side eq 'top';
    return 'horizontal' if $side eq 'bottom';
    return 'vertical'   if $side eq 'left';
    return 'vertical'   if $side eq 'right';
    return;
}

sub stroke_dash_array {
    goto &strokeDashArray;
}
sub strokeDashArray {
    my (%args) = @_;
    my $length  = $args{length} // 0;
    my $spacing = $args{spacing};
    if ($length < SVG_DOTTED_LINE_FUDGE_FACTOR) {
        $length = SVG_DOTTED_LINE_FUDGE_FACTOR;
    }
    return sprintf('%.3f %.3f', $length, $spacing - $length);
}

sub stroke_dash_offset {
    goto &strokeDashOffset;
}
sub strokeDashOffset {
    my (%args) = @_;
    my $min          = $args{min};
    my $max          = $args{max};
    my $length       = $args{length} // 0;
    my $center       = $args{center} // (($min + $max) / 2);
    my $spacing      = $args{spacing};
    my $centerOffset = $args{centerOffset} // 0;
    if ($length < SVG_DOTTED_LINE_FUDGE_FACTOR) {
        $length = SVG_DOTTED_LINE_FUDGE_FACTOR;
    }
    my $offset = $min - $center + $length / 2 - ($centerOffset * $spacing);
    while (snapnum($offset) < 0) {
        $offset += $spacing;
    }
    return sprintf('%.3f', $offset);
}

1;
