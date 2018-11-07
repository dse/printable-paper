package My::Printable::Element::Line;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";

use base qw(My::Printable::Element);

sub compute {
    my ($self) = @_;
}

sub draw {
    my ($self) = @_;
}

1;
