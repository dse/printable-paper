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
                 FUDGE_FACTOR)],
    around => [qw(aroundUnit
                  aroundUnitX
                  aroundUnitY)],
);
our @EXPORT_OK = (
    qw(exclude
       round3
       with_temp
       linear_interpolate),
    @{$EXPORT_TAGS{const}},
    @{$EXPORT_TAGS{around}},
);
our @EXPORT = ();

use constant USE_SVG_PATTERNS_FOR_DOT_GRIDS => 0;
use constant USE_SVG_DOTTED_LINES_FOR_DOT_GRIDS => 1;
use constant USE_SVG_FILTER_INKSCAPE_BUG_WORKAROUND => 0;
use constant FUDGE_FACTOR => 0.0001;

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

1;
