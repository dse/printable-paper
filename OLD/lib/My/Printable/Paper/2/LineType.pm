package My::Printable::Paper::2::LineType;
use warnings;
use strict;
use v5.10.0;

use Moo;

has id         => (is => 'rw');
has width      => (is => 'rw', default => '1 dot');
has style      => (is => 'rw', default => 'solid'); # solid, dashed, dotted
has stroke     => (is => 'rw', default => 'blue');
has fill       => (is => 'rw');
has paper      => (is => 'rw');
has dashes     => (is => 'rw', default => 1); # per grid unit
has dots       => (is => 'rw', default => 1); # per grid unit
has opacity    => (is => 'rw');
has dashLength => (is => 'rw', default => 0.5);
has r          => (is => 'rw');

sub getGridDashArguments {
    my ($self, %args) = @_;

    my $coordinates = $args{coordinates};
    my $axis        = $args{axis};
    my $isClosed    = $args{isClosed};
    my $parentId    = $args{parentId};
    my $groupId     = $args{groupId};
    my $spacing     = $args{spacing};

    my @points = $self->paper->coordinate($coordinates, $axis);
    my $isPointSeries = eval { $coordinates->isa('My::Printable::Paper::2::PointSeries') };
    if ($isPointSeries) {
        $spacing = $self->paper->coordinate($spacing // $coordinates->step);
    } else {
        $spacing = $self->paper->coordinate($spacing);
    }
    my $group = $self->paper->svgGroupElement(id => $groupId, parentId => $parentId);
    my ($point1, $point2, $isExtended) = $self->paper->getGridStartEnd(
        axis => $args{axis},
        coordinates => $coordinates,
        isClosed => $args{isClosed},
    );

    if (!$self->isDashedOrDotted) {
        return (
            point1        => $point1,
            point2        => $point2,
            points        => \@points,
            isExtended    => $isExtended,
            spacing       => $spacing,
        );
    }

    my $dashLength = $self->isDashed ? ($spacing * $self->dashLength) : 0;
    my $dashSpacing = $spacing;
    my $dashLineStart = $point1;
    my $dashCenterAt = $isClosed ? $points[0] : undef;
    if ($self->isDashed) {
        $dashLength /= $self->dashes;
        $dashSpacing /= $self->dashes;
    } elsif ($self->isDotted) {
        $dashLength /= $self->dots;
        $dashSpacing /= $self->dots;
    }
    my %dashArgs = (
        dashLength    => $dashLength,
        dashSpacing   => $dashSpacing,
        dashLineStart => $dashLineStart,
        dashCenterAt  => $dashCenterAt,
        point1        => $point1,
        point2        => $point2,
        points        => \@points,
        isExtended    => $isExtended,
        spacing       => $spacing,
    );
    return %dashArgs;
}

sub isDashed {
    my $self = shift;
    return $self->style eq 'dashed';
}

sub isDotted {
    my $self = shift;
    return $self->style eq 'dotted';
}

sub isDashedOrDotted {
    my $self = shift;
    return $self->isDashed || $self->isDotted;
}

sub getComputedCSS {
    my $self = shift;

    my $stroke  = $self->parseColor($self->stroke);
    my $fill    = $self->parseColor($self->fill);
    my $width   = $self->paper->coordinate($self->width);
    my $id      = $self->id;
    my $opacity = $self->opacity;
    my $r       = $self->r;

    my $result = '';
    $result .= <<"END";
        .${id} {
END
    $result .= <<"END" if defined $stroke;
            stroke: ${stroke};
END
    if (defined $fill) {
        $result .= <<"END";
            fill: ${fill};
END
    } else {
        $result .= <<"END";
            fill: none;
END
    }
    $result .= <<"END" if defined $opacity;
            opacity: ${opacity};
END
    $result .= <<"END" if defined $r;
            r: ${r};
END
    $result .= <<"END";
            stroke-width: ${width}pt;
        }
END
    return $result;
}

use List::Util qw(any);

sub parseColor {
    my $self = shift;
    my $value = shift;
    return undef if !defined $value || $value eq '';
    return '#b3b3ff' if $value eq 'blue';
    return '#5aff5a' if $value eq 'green';
    return '#ff9e9e' if $value eq 'red';
    return '#bbbbbb' if $value eq 'gray';
    return '#ffab57' if $value eq 'orange';
    return '#ff8cff' if $value eq 'magenta';
    return '#1cffff' if $value eq 'cyan';
    return '#ffff00' if $value eq 'yellow';
    return '#000000' if $value eq 'black';
    return '#95c9d7' if any { $_ eq $value } qw(non-repro-blue non-photo-blue);
    return $value;
}

1;
