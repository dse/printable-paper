package My::Printable::Paper::2::Paper::DarrensGrid;
use warnings;
use strict;

use Moo;

extends 'My::Printable::Paper::2::Paper';

has 'marginLine'       => (is => 'rw', default => '1in');
has 'marginLineLeft'   => (is => 'rw');
has 'marginLineRight'  => (is => 'rw');
has 'marginLineTop'    => (is => 'rw');
has 'marginLineBottom' => (is => 'rw');

has 'majorLineType' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'major',
            width => '1 printerdots',
        );
    }
);
has 'minorLineType' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'minor',
            width => '1 printerdot',
            style => 'dashed',
            dashes => 3,        # 2   3   4
            dashLength => 3/8,  # 1/4 3/8 1/2
        );
    }
);
has 'marginLineType' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'margin',
            width => '4 printerdots',
            stroke => 'red',
        );
    }
);

has 'majorGridX' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addXPointSeries(
            id => 'major-x',
            canShiftPoints => 1,
            step => $self->gridSpacingX,
        );
    }
);
has 'majorGridY' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addYPointSeries(
            id => 'major-y',
            canShiftPoints => 1,
            step => $self->gridSpacingY,
        );
    }
);

has 'minorGridX' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addXPointSeries(
            id => 'minor-x',
            step => '1/3 gridunit',
            origin => $self->majorGridX->computedOrigin,
            canExclude => $self->majorGridX,
        );
    }
);
has 'minorGridY' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addYPointSeries(
            id => 'minor-y',
            step => '1/3 gridunit',
            origin => $self->majorGridY->computedOrigin,
            canExclude => $self->majorGridY,
        );
    }
);

sub draw {
    my ($self) = @_;
    $self->majorGridX->compute();
    $self->majorGridY->compute();
    $self->minorGridX->compute();
    $self->minorGridY->compute();
    $self->startSVG();

    $self->drawGrid(
        groupId => 'minor',
        x => $self->minorGridX,
        y => $self->minorGridY,
        lineType => $self->minorLineType
    );

    $self->drawGrid(
        groupId => 'major',
        x => $self->majorGridX,
        y => $self->majorGridY,
        lineType => $self->majorLineType
    );

    $self->drawVerticalLines(
        groupId => 'left-margin-line',
        x => $self->majorGridX->nearest($self->marginLineLeft // $self->marginLine),
        lineType => $self->marginLineType
    );
    $self->drawHorizontalLines(
        groupId => 'top-margin-line',
        y => $self->majorGridY->nearest($self->marginLineTop // $self->marginLine),
        lineType => $self->marginLineType
    );
    $self->drawVerticalLines(
        groupId => 'right-margin-line',
        x => $self->majorGridX->nearest(($self->marginLineRight // $self->marginLine) . ' from right'),
        lineType => $self->marginLineType
    );
    $self->drawHorizontalLines(
        groupId => 'bottom-margin-line',
        y => $self->majorGridY->nearest(($self->marginLineBottom // $self->marginLine) . ' from bottom'),
        lineType => $self->marginLineType
    );

    $self->endSVG();
}

1;
