package My::Printable::Paper::PaperSize;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::Util qw(:const :trigger snapcmp flatten);
use My::Printable::Paper::SizeDefinitions;
use My::Printable::Paper::Dimension;

use Moo;

around BUILDARGS => sub {
    my ($orig, $self) = (shift, shift);
    if (scalar @_ % 2 == 1) {
        my $value = shift;
        my $hash = $self->$orig(@_);
        my $result = My::Printable::Paper::SizeDefinitions::parse($value);
        $hash->{width}    //= $result->{width};
        $hash->{height}   //= $result->{height};
        $hash->{name}     //= $result->{name};
        $hash->{unitType} //= $result->{unitType};
        return $hash;
    } else {
        my ($width, $height) = (shift, shift);
        my $value = $width . 'x' . $height;
        my $hash = $self->$orig(@_);
        my $result = My::Printable::Paper::SizeDefinitions::parse($value);
        $hash->{width}    //= $result->{width};
        $hash->{height}   //= $result->{height};
        $hash->{name}     //= $result->{name};
        $hash->{unitType} //= $result->{unitType};
        return $hash;
    }
};

has name => (
    is => 'rw',
    default => sub {
        return DEFAULT_PAPER_SIZE_NAME;
    },
    trigger => triggerWrapper(\&triggerName),
);

has width => (
    is => 'rw',
    default => sub {
        return My::Printable::Paper::Dimension->new(DEFAULT_WIDTH);
    },
    trigger => triggerWrapper(\&triggerWidth),
);

has height => (
    is => 'rw',
    default => sub {
        return My::Printable::Paper::Dimension->new(DEFAULT_HEIGHT);
    },
    trigger => triggerWrapper(\&triggerHeight),
);

has orientation => (
    is => 'rw',
    default => sub {
        return DEFAULT_ORIENTATION;
    },
    trigger => triggerWrapper(\&triggerOrientation),
);

sub triggerName {
    my ($self, $value) = @_;
    my ($name, $width, $height, $unitType) =
        My::Printable::Paper::SizeDefinitions->parse($value);
    $self->width->set($width);
    $self->height->set($height);
    $self->width->unitType($unitType);
    $self->height->unitType($unitType);
    $self->setOrientationFromDimensions();
}

sub triggerWidth {
    my ($self, $value) = @_;
    if (!eval { $value->isa('My::Printable::Paper::Dimension') }) {
        $self->width(My::Printable::Paper::Dimension->new($value));
    }
    $self->setOrientationFromDimensions();
}

sub triggerHeight {
    my ($self, $value) = @_;
    if (!eval { $value->isa('My::Printable::Paper::Dimension') }) {
        $self->height(My::Printable::Paper::Dimension->new($value));
    }
    $self->setOrientationFromDimensions();
}

sub triggerOrientation {
    my ($self, $value) = @_;
    my $old = $self->guessOrientation();
    if ($value eq 'portrait' && $old eq 'landscape') {
        my $width  = $self->width;
        my $height = $self->height;
        $self->height($width);
        $self->width($height);
    } elsif ($value eq 'landscape' && $old eq 'portrait') {
        my $width  = $self->width;
        my $height = $self->height;
        $self->height($width);
        $self->width($height);
    } elsif ($value eq $old) {
        # do nothing
    } else {
        die("cannot change orientation from '$old' to '$value'");
    }
}

sub setOrientationFromDimensions {
    my ($self) = @_;
    my $orientation = $self->guessOrientation();
    $self->orientation($orientation);
}

sub guessOrientation {
    my ($self, $width, $height) = @_;
    $width  //= $self->width;
    $height //= $self->height;
    $width  = $width->asPoints  if ref $width;
    $height = $height->asPoints if ref $height;
    my $aspect = $width / $height;
    $aspect = 1.0 if !snapcmp($aspect, 1.0);
    return 'landscape' if $aspect > 1;
    return 'portrait'  if $aspect < 1;
    return 'square';
}

sub isPaperSizeClass {
    my ($self, $size) = @_;
    my $sqpt_size = My::Printable::Paper::SizeDefinitions->get_square_points($size);
    my $sqpt = $self->getSquarePoints();
    return 0 if !$sqpt_size || !$sqpt;
    my $ratio = $sqpt / $sqpt_size;
    return $ratio >= 0.8 && $ratio <= 1.25;
}

sub getSquarePoints {
    my ($self) = @_;
    return $self->width->asPoints * $self->height->asPoints;
}

sub isA4SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('letter') || $self->isPaperSizeClass('a4');
}

sub isA5SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('halfletter') || $self->isPaperSizeClass('a5');
}

sub isA6SizeClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('quarterletter') || $self->isPaperSizeClass('a6');
}

sub isTravelersClass {
    my ($self) = @_;
    return $self->isPaperSizeClass('travelers');
}

1;
