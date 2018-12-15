package My::Printable::Element::Rectangle;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

# x1, x2, y1, and y2 inherited from My::Printable::Element.

public 'width', set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public 'height', set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};

public 'rx', set => sub {
    my ($self, $value) = @_;
    return $self->ptX($value);
};
public 'ry', set => sub {
    my ($self, $value) = @_;
    return $self->ptY($value);
};
public 'r', set => sub {
    my ($self, $value) = @_;
    return $self->pt($value);
};

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use base qw(My::Printable::Element);

sub draw {
    my ($self) = @_;

    my $x;
    my $width;

    if (defined $self->x1) {
        $x = $self->x1;
        if (defined $self->width) {
            $width = $self->width;
        } elsif (defined $self->x2) {
            $width = $self->x2 - $self->x1;
        } else {
            $width = $self->rightMarginX - $self->x1;
        }
    } else {
        if (defined $self->width) {
            $width = $self->width;
            if (defined $self->x2) {
                $x = $self->x2 - $self->width;
            } else {
                $x = $self->ptX('50%') - $self->width;
            }
        } else {
            $x = $self->leftMarginX;
            if (defined $self->x2) {
                $width = $self->x2 - $self->leftMarginX;
            } else {
                $width = $self->rightMarginX - $self->leftMarginX;
            }
        }
    }

    my $y;
    my $height;

    if (defined $self->y1) {
        $y = $self->y1;
        if (defined $self->height) {
            $height = $self->height;
        } elsif (defined $self->y2) {
            $height = $self->y2 - $self->y1;
        } else {
            $height = $self->bottomMarginY - $self->y1;
        }
    } else {
        if (defined $self->height) {
            $height = $self->height;
            if (defined $self->y2) {
                $y = $self->y2 - $self->height;
            } else {
                $y = $self->ptY('50%') - $self->height;
            }
        } else {
            $y = $self->topMarginY;
            if (defined $self->y2) {
                $height = $self->y2 - $self->topMarginY;
            } else {
                $height = $self->bottomMarginY - $self->topMarginY;
            }
        }
    }

    my $rx = $self->rx // $self->r // 0;
    my $ry = $self->ry // $self->r // 0;

    my $cssClass = $self->cssClass // "blue line";
    my $rectangle = $self->createSVGRectangle(
        x => $x, y => $y, width => $width, height => $height,
        rx => $rx, ry => $ry,
        cssClass => $cssClass,
    );
    $self->appendSVGElement($rectangle);
}

1;
