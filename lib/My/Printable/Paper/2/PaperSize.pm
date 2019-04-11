package My::Printable::Paper::2::PaperSize;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::PaperSizeList;
use My::Printable::Paper::2::Regexp qw($RE_PAPERSIZE parseMixedFraction);

use Moo;

has width       => (is => 'rw', default => '8.5in');
has height      => (is => 'rw', default => '11in');
has orientation => (is => 'rw', default => 'portrait');
has name        => (is => 'rw', default => 'letter');
has paper       => (is => 'rw');

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $value;
    if (scalar @_ == 1) {
        return $self->$orig(@_);
    }
    if (scalar @_ % 2 == 1) {
        $value = shift;
        my %args = @_;
        my $paper = $args{paper};
        if ($value =~ m{^\s*$RE_PAPERSIZE\s*$}) {
            my $unit1 = $+{unit1};
            my $unit2 = $+{unit2};
            my $width  = parseCoordinate($+{mixed1}, $+{numer1}, $+{denom1});
            my $height = parseCoordinate($+{mixed2}, $+{numer2}, $+{denom2});
            $unit1 //= $unit2 if defined $unit2;
            $unit2 //= $unit1 if defined $unit1;

            # convert units to points
            if (defined $unit1) {
                $unit1 = My::Printable::Paper::2::Unit::Parse($unit1, 'x');
            } else {
                $unit1 = 1;
            }
            if (defined $unit2) {
                $unit2 = My::Printable::Paper::2::Unit::Parse($unit2, 'y');
            } else {
                $unit2 = 1;
            }

            return $self->$orig(width => $width, height => $height, @_);
        }
        return $self->$orig(width  => 8.5  * 72,
                            height => 11   * 72,
                            name   => 'letter', @_)
            if grep { $_ eq $value } qw(letter);
        return $self->$orig(width  => 5.5  * 72,
                            height => 8.5  * 72,
                            name   => 'halfletter', @_)
            if grep { $_ eq $value } qw(halfletter half-letter);
        return $self->$orig(width  => 4.25 * 72,
                            height => 5.5  * 72,
                            name   => 'quarterletter', @_)
            if grep { $_ eq $value } qw(quarterletter quarter-letter);
        return $self->$orig(width  => 250 / sqrt(sqrt(2)) * 72 / 25.4,
                            height => 250 * sqrt(sqrt(2)) * 72 / 25.4,
                            name   => 'a4', @_)
            if grep { $_ eq $value } qw(a4);
        return $self->$orig(width  => 125 * sqrt(sqrt(2)) * 72 / 25.4,
                            height => 250 / sqrt(sqrt(2)) * 72 / 25.4,
                            name   => 'a5', @_)
            if grep { $_ eq $value } qw(a5);
        return $self->$orig(width  => 125 / sqrt(sqrt(2)) * 72 / 25.4,
                            height => 125 * sqrt(sqrt(2)) * 72 / 25.4,
                            name   => 'a6', @_)
            if grep { $_ eq $value } qw(a6);
        die("invalid paper size: '$value'");
    }
    return $self->$orig(@_);
};

1;
