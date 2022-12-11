package My::RuledPaper::MonkeyPatch::Drawing;
use warnings;
use strict;

package My::RuledPaper;

sub line {
    my ($self, $x1, $y1, $x2, $y2, %args) = @_;
    return $self->add('line', x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, %args);
}

sub circle {
    my ($self, $cx, $cy, $r, %args) = @_;
    return $self->add('circle', cx => $cx, cy => $cy, r => $r, %args);
}

sub ellipse {
    my ($self, $cx, $cy, $rx, $ry, %args) = @_;
    return $self->add('ellipse', cx => $cx, cy => $cy, rx => $rx, ry => $ry, %args);
}

sub rect {
    my ($self, $x, $y, $width, $height, $rx, $ry, %args) = @_;
    return $self->add('rect', x => $x, y => $y, width => $width, height => $height,
                      rx => $rx, ry => $ry, %args);
}

sub image {
    my ($self, $x, $y, $width, $height, $href, $preserveAspectRatio, %args) = @_;
    return $self->add('image', x => $x, y => $y, width => $width, height => $height,
                      href => $href, preserveAspectRatio => $preserveAspectRatio, %args);
}

sub path {
    my ($self, $d, %args) = @_;
    $d = _split($d) if ref $d eq 'ARRAY';
    return $self->add('path', d => $d, %args);
}

sub polygon {
    my ($self, $points, %args) = @_;
    $points = _split($points) if ref $points eq 'ARRAY';
    return $self->add('polygon', points => $points, %args);
}

sub polyline {
    my ($self, $points, %args) = @_;
    $points = _split($points) if ref $points eq 'ARRAY';
    return $self->add('polyline', points => $points, %args);
}

# [[0, 0], [0, 100], [100, 100], [100, 0]]
# ['0,0', '0,100', '100,100', '100,0']
# '0,0 0,100 100,100 100,0'
# ['M', [0, 0], 'L', [0, 100], 'L', [100, 100], 'L', [100, 0], 'Z']
sub _split {
    my $x = shift;
    return $x if ref $x ne 'ARRAY';
    return join(' ', map { ref $_ eq 'ARRAY' ? join(',', @$_) : $_ } @$x);
}

1;
