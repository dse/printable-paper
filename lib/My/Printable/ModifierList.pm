package My::Printable::ModifierList;
use warnings;
use strict;
use v5.10.0;

use List::Util qw(any all);

sub new {
    my ($class, @modifiers) = @_;
    my $self = bless({}, $class);
    $self->{hash} = {};
    $self->{list} = [];
    if (scalar @modifiers) {
        $self->add(@modifiers);
    }
    return $self;
}

sub has {
    my ($self, $modifier) = @_;
    return exists $self->{hash}->{$modifier};
}

sub hasAny {
    my ($self, @modifiers) = @_;
    return any { $self->has($_) } @modifiers;
}

sub hasAll {
    my ($self, @modifiers) = @_;
    return all { $self->has($_) } @modifiers;
}

sub add {
    my ($self, @modifiers) = @_;
    foreach my $modifier (@modifiers) {
        $self->{hash}->{$modifier} = 1;
        if (!grep { $_ eq $modifier } @{$self->{list}}) {
            push(@{$self->{list}}, $modifier);
        }
    }
}

sub remove {
    my ($self, @modifiers) = @_;
    foreach my $modifier (@modifiers) {
        delete $self->{hash}->{$modifier};
        @{$self->{list}} = grep { $_ ne $modifier } @{$self->{list}};
    }
}

sub clear {
    my ($self) = @_;
    %{$self->{hash}} = ();
    @{$self->{list}} = [];
}

sub set {
    my ($self, @modifiers) = @_;
    $self->clear;
    $self->add(@modifiers);
}

1;
