package My::Printable::Paper::2::LineType;
use warnings;
use strict;
use v5.10.0;

use Moo;

has id      => (is => 'rw');
has width   => (is => 'rw', default => '1 dot');
has style   => (is => 'rw', default => 'solid'); # solid, dashed, dotted
has stroke  => (is => 'rw', default => 'blue');
has fill    => (is => 'rw');
has paper   => (is => 'rw');
has dashes  => (is => 'rw', default => 1);
has dots    => (is => 'rw', default => 1);
has opacity => (is => 'rw');

sub getCSS {
    my $self = shift;

    my $stroke  = $self->parseColor($self->stroke);
    my $fill    = $self->parseColor($self->fill);
    my $width   = $self->paper->coordinate($self->width);
    my $id      = $self->id;
    my $opacity = $self->opacity;

    my $result = '';
    $result .= <<"END";
        * {
            stroke-linecap: round;
            stroke-linejoin: round;
        }
        .${id} {
END
    $result .= <<"END" if defined $stroke;
            stroke: ${stroke};
END
    $result .= <<"END" if defined $fill;
            fill: ${fill};
END
    $result .= <<"END" if defined $opacity;
            opacity: ${opacity};
END
    $result .= <<"END";
            stroke-width: ${width}pt;
        }
END
    return $result;
}

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
