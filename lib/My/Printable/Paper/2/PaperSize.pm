package My::Printable::Paper::2::PaperSize;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::PaperSizeList qw(getPaperSizeByName);
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
        my $result = getPaperSizeByName($value);
        if ($result) {
            return $self->$orig(width  => $result->{width},
                                height => $result->{height},
                                name   => $result->{name},
                                @_);
        }
        die("invalid paper size: '$value'");
    }
    return $self->$orig(@_);
};

1;
