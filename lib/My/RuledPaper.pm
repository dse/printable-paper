package My::RuledPaper;
use warnings;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self;
}

use XML::LibXML;
use Scalar::Util qw(looks_like_number);

sub add {
    my ($self, $name, %attr) = @_;
    my $object = {
        name => $name,
        attr => \%attr,
    };
    push(@{$self->{objects}}, $object);
    return $object;
}

sub svg {
    my ($self) = @_;
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('svg');
    my $width = $self->{width};
    my $height = $self->{height};
    my $viewbox = sprintf('%.3f %.3f %.3f %.3f', 0, 0, $self->{width}, $self->{height});
    $root->setAttribute('version', '1.1');
    $root->setAttribute('width', sprintf('%.3fpx', $self->{width}));
    $root->setAttribute('height', sprintf('%.3fpx', $self->{height}));
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
        foreach my $name (sort { $a cmp $b } grep { !/^_/ } keys %$attr) {
            my $value = $attr->{$name};
            next if !defined $value;
            my $attrName = $name;
            $attrName =~ s{_}{-}g;
            if (looks_like_number($value)) {
                $elt->setAttribute($name, sprintf('%.3f', $value));
            } else {
                $elt->setAttribute($name, $value);
            }
        }
        my $text = $attr->{_content};
        if (defined $text) {
            $elt->appendText($text);
        }
        $g->appendChild($elt);
    }
    return $doc->toString(2);
}

1;
