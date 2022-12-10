package My::RuledPaper;
use warnings;
use strict;

our %sizes;
BEGIN {
    %sizes = (
        letter      => [8.5, 11, 'in'],
        half_letter => [5.5, 8.5, 'in'],
        a4          => [250 / sqrt(sqrt(2)), 250 * sqrt(sqrt(2)), 'mm'],
        a5          => [125 * sqrt(sqrt(2)), 250 / sqrt(sqrt(2)), 'mm'],
    );
}

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    if (defined $self->{size}) {
        my $size = $sizes{$self->{size}};
        if (!defined $size) {
            die("unknown paper size $self->{size}\n");
        }
        $self->{width}  //= $size->[0];
        $self->{height} //= $size->[1];
        $self->{unit}   //= $size->[2];
    } else {
        my $size = 'a4';
        $self->{width}  //= $sizes{$size}[0];
        $self->{height} //= $sizes{$size}[1];
        $self->{unit}   //= $sizes{$size}[2];
    }
    return $self;
}

use XML::LibXML;
use Scalar::Util qw(looks_like_number);

sub add {
    my ($self, $name, %attr) = @_;
    push(@{$self->{objects}}, {
        name => $name,
        attr => \%attr,
    });
}

sub svg {
    my ($self) = @_;
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('svg');
    my $width = $self->{width};
    my $height = $self->{height};
    my $unit = $self->{unit};
    my $viewbox = sprintf('%.3f %.3f %.3f %.3f',
                          0, 0, $self->px($self->{width}), $self->px($self->{height}));
    $root->setAttribute('width', sprintf('%.3f%s', $self->{width}, $self->{unit}));
    $root->setAttribute('height', sprintf('%.3f%s', $self->{height}, $self->{unit}));
    $root->setAttribute('viewBox', $viewbox);
    $root->setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    $doc->setDocumentElement($root);
    if (defined $self->{style}) {
        my $style = $doc->createElement('style');
        $style->appendText($self->{style});
        $root->appendChild($style);
    }
    my $g = $doc->createElement('g');
    $g->setAttribute('id', 'document');
    $root->appendChild($g);
    foreach my $object (@{$self->{objects}}) {
        my $name = $object->{name};
        my $attr = $object->{attr};
        my $elt = $doc->createElement($name);
        foreach my $name (sort { $a cmp $b } keys %$attr) {
            my $value = $attr->{$name};
            next if !defined $value;
            if (looks_like_number($value)) {
                $elt->setAttribute($name, sprintf('%.3f', $self->px($value)));
            } else {
                $elt->setAttribute($name, $value);
            }
        }
        $g->appendChild($elt);
    }
    return $doc->toString(2);
}

our %units;
BEGIN {
    %units = (
        #     v-- how many of this unit to an inch
        mm => 25.4 / 96,
        cm => 2.54 / 96,
        in => 1    / 96,
        pt => 72   / 96,
        px => 96   / 96,
        pc => 6    / 96,
        #            ^---- how many pixels to an inch
        # viewbox units need to be in pixels in order for css dimensions to work properly
    );
}

sub to {
    my ($self, $dimen, $toUnit) = @_;
    my $fromUnit;
    if ($dimen =~ s{[a-z]+$}{}) {
        $fromUnit = $&;
    } else {
        $fromUnit = $self->{unit};
    }
    $dimen /= $units{$fromUnit};
    $dimen *= $units{$toUnit};
    return $dimen;
}
sub px { my ($self, $dimen) = @_; return $self->to($dimen, 'px'); }
sub pt { my ($self, $dimen) = @_; return $self->to($dimen, 'pt'); }
sub pc { my ($self, $dimen) = @_; return $self->to($dimen, 'pc'); }
sub in { my ($self, $dimen) = @_; return $self->to($dimen, 'in'); }
sub mm { my ($self, $dimen) = @_; return $self->to($dimen, 'mm'); }
sub cm { my ($self, $dimen) = @_; return $self->to($dimen, 'cm'); }
sub dimen { my ($self, $dimen) = @_; return $self->to($dimen, $self->{unit}); }

1;
