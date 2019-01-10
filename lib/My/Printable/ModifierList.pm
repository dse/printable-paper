package My::Printable::ModifierList;
use warnings;
use strict;
use v5.10.0;

use Moo;

use List::Util qw(any all);

# There is some rigmarole that exists because we want to define a
# method named 'has'.

BEGIN {
    has hash => (is => 'rw', default => sub { return {}; });
    has list => (is => 'rw', default => sub { return []; });
}

no warnings 'redefine';
sub has {
    my ($self, $key) = @_;
    my $hash = $self->hash;
    return exists $hash->{$key};
}
use warnings 'redefine';

sub set {
    my ($self, $key, $value) = @_;
    $self->hash->{$key} = $value;
    if (!grep { $_ eq $key } @{$self->list}) {
        push(@{$self->list}, $key)
    }
}

sub get {
    my ($self, $key) = @_;
    return $self->hash->{$key};
}

sub delete {
    my ($self, $key) = @_;
    my $result = delete $self->hash->{$key};
    @{$self->list} = grep { $_ ne $key } @{$self->list};
    return $result;
}

sub clear {
    my ($self) = @_;
    %{$self->hash} = ();
    @{$self->list} = ();
}

sub setModifiers {
    my ($self, @modifiers) = @_;
    $self->clear();
    $self->addModifiers(@modifiers);
}

sub addModifiers {
    my ($self, @modifiers) = @_;
    foreach my $modifier (@modifiers) {
        my ($key, $value);
        if ($modifier =~ m{\A(.*?)=(.*)\z}) {
            $key = $1;
            $value = $2;
        } else {
            $key = $modifier;
            $value = 1;
        }
        $self->set($key, $value);
    }
}

1;
