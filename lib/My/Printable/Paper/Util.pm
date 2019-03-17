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
                  aroundUnitY
                  makeAroundArrayAccessor
                  makeAroundHashAccessor)],
    trigger => [qw(triggerWrapper
                   triggerUnit
                   triggerUnitX
                   triggerUnitY)],
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
       strokeDashOffset
       flatten
       triggerWrapper
       triggerUnit
       triggerUnitX
       triggerUnitY),
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
    shift if scalar @_ > 0 && defined blessed $_[0];
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
    shift if scalar @_ > 0 && defined blessed $_[0];
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
    my $dashStartAt = $center - $length / 2 + ($centerOffset * $spacing);
    my $offset = $min - $dashStartAt;
    while (snapnum($offset) < 0) {
        $offset += $spacing;
    }
    return sprintf('%.3f', $offset);
}

sub flatten {
    return map {
        eval { ref $_ eq 'ARRAY' } ? @$_ : $_
    } @_;
}

sub makeAroundArrayAccessor {
    my %args = @_;
    my $set = $args{set};
    return sub {
        my $orig = shift;
        my $self = shift;
        if (!scalar @_) {
            return $self->$orig;
        }
        my $arrayRefOrIndex = shift;
        if (eval { ref $arrayRefOrIndex eq 'ARRAY' }) {
            return $self->$orig($arrayRefOrIndex);
        }
        my $index = $arrayRefOrIndex;
        my $arrayRef = $self->$orig();
        if (!scalar @_) {
            return $arrayRef->[$index];
        }
        my $value = shift;
        if ($set) {
            $value = $self->$set($value);
        }
        return $arrayRef->[$index] = $value;
    };
}

sub makeAroundHashAccessor {
    my %args = @_;
    my $set = $args{set};
    return sub {
        my $orig = shift;
        my $self = shift;
        if (!scalar @_) {
            return $self->$orig;
        }
        my $hashRefOrKey = shift;
        if (eval { ref $hashRefOrKey eq 'HASH' }) {
            return $self->$orig($hashRefOrKey);
        }
        my $key = $hashRefOrKey;
        my $hashRef = $self->$orig();
        if (!scalar @_) {
            return $hashRef->{$key};
        }
        my $value = shift;
        if ($set) {
            $value = $self->$set($value);
        }
        return $hashRef->{$key} = $value;
    };
}

sub triggerWrapper {
    my ($sub) = @_;
    my $wrapper = sub {
        state $x = 0;
        return if $x;
        $x += 1;
        my $result;
        my @result;
        if (wantarray) {
            @result = $sub->(@_);
        } else {
            $result = $sub->(@_);
        }
        $x -= 1;
        return @result if wantarray;
        return $result;
    };
    return $wrapper;
}

sub triggerUnit {
    my ($name) = @_;
    my $trigger = sub {
        my ($self, $value) = @_;
        if ($self->can('pt')) {
            $value = $self->pt($value);
        } else {
            $value = My::Printable::Paper::Unit->pt($value);
        }
        $self->$name($value);
    };
    return triggerWrapper($trigger);
}

sub triggerUnitX {
    my ($name) = @_;
    my $trigger = sub {
        my ($self, $value) = @_;
        $value = $self->ptX($value);
        $self->$name($value);
    };
    return triggerWrapper($trigger);
}

sub triggerUnitY {
    my ($name) = @_;
    my $trigger = sub {
        my ($self, $value) = @_;
        $value = $self->ptY($value);
        $self->$name($value);
    };
    return triggerWrapper($trigger);
}

1;
