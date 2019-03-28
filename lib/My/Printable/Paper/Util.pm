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
                 SVG_DOTTED_LINE_FUDGE_FACTOR
                 DEFAULT_PAPER_SIZE_NAME
                 DEFAULT_WIDTH
                 DEFAULT_HEIGHT
                 DEFAULT_ORIENTATION
                 DEFAULT_UNIT_TYPE
                 DEFAULT_COLOR_TYPE)],
    trigger => [qw(triggerWrapper
                   triggerUnit
                   triggerUnitX
                   triggerUnitY
                   createDimensionTrigger
                   createPaperSizeTrigger)],
    around => [qw(aroundDimension)],
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
       flatten),
    @{$EXPORT_TAGS{const}},
    @{$EXPORT_TAGS{trigger}},
    @{$EXPORT_TAGS{around}},
);
our @EXPORT = ();

use constant DEFAULT_PAPER_SIZE_NAME => 'letter';
use constant DEFAULT_WIDTH           => 612;
use constant DEFAULT_HEIGHT          => 792;
use constant DEFAULT_ORIENTATION     => 'portrait';
use constant DEFAULT_UNIT_TYPE       => 'imperial';
use constant DEFAULT_COLOR_TYPE      => 'color';

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
    my @args = @_;
    if (scalar @args % 2 == 1) {
        # from: ('name', %args)
        # to:   (name => 'name', %args)
        unshift(@args, 'name');
    }
    my %args = @args;
    my $name = $args{name};
    my $axis = $args{axis};
    my $edge = $args{edge};

    my $isX          = defined $axis && $axis eq 'x';
    my $isY          = defined $axis && $axis eq 'y';
    my $isForFarEdge = defined $edge && $edge eq 'far';

    my $trigger = sub {
        my ($self, $value) = @_;
        my @pt;
        if ($isX) {
            @pt = $self->ptX($value);
        } elsif ($isY) {
            @pt = $self->ptY($value);
        } elsif ($self->can('pt')) {
            @pt = $self->pt($value);
        } else {
            @pt = My::Printable::Paper::Unit->pt($value);
        }
        my ($pt, $unitType, $isFromFarEdge) = @pt;

        my $isOppositeEdge = (($isFromFarEdge && !$isForFarEdge) ||
                                  (!$isFromFarEdge && $isForFarEdge));
        if ($isOppositeEdge) {
            if ($isX) {
                $pt = $self->width - $pt if $self->can('width');
            } elsif ($isY) {
                $pt = $self->height - $pt if $self->can('height');
            }
        }

        $self->$name($pt);
    };
    return triggerWrapper($trigger);
}

sub triggerUnitX {
    my @args = @_;
    return triggerUnit(@args, axis => 'x');
}

sub triggerUnitY {
    my @args = @_;
    return triggerUnit(@args, axis => 'y');
}

sub createDimensionTrigger {
    my %args = @_;
    my $axis = $args{axis};
    my $name = $args{name};
    my $trigger = sub {
        my ($self, $value) = @_;
        $self->$name->set($value);
    };
    return triggerWrapper($trigger);
}

sub createPaperSizeTrigger {
    my (%args) = @_;
    my $name = $args{name};
    my $trigger = sub {
        my ($self, $value) = @_;
        $self->$name->set($value);
    };
    return triggerWrapper($trigger);
}

sub aroundDimension {
    my ($orig, $self) = @_;
    if (scalar @_) {
        return $self->$orig(@_);
    }
    return $self->$orig()->asPoints;
}

sub aroundPaperSize {
    my ($orig, $self) = @_;
    if (scalar @_) {
        return $self->$orig(@_);
    }
    if (wantarray) {
        my $width = $self->$orig->width;
        my $height = $self->$orig->height;
        return ($width, $height);
    }
    return $self->$orig();
}

1;
