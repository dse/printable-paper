package My::Printable::Paper::2::Paper::Grid;
use warnings;
use strict;
use v5.10.0;

use Moo;

extends 'My::Printable::Paper::2::Paper';

has majorGradiations => (is => 'rw', default => 5);
has minorGradiations => (is => 'rw', default => 0);

has majorLineType => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'major',
            width => '4pd',
        );
    }
);
has minorLineType => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'minor',
            width => '2pd',
        );
    }
);
has feintLineType => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'feint',
            width => '1pd',
        );
    }
);

has majorGridX => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addXPointSeries(
            id => 'major-x',
            step => $self->gridSpacingX,
            canShiftPoints => 1,
        );
    }
);
has minorGridX => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return unless $self->majorGradiations >= 2;
        return $self->addXPointSeries(
            id => 'minor-x',
            step => $self->xx($self->gridSpacingX) / ($self->majorGradiations),
            origin => $self->majorGridX->computedOrigin,
        );
    }
);
has feintGridX => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return unless $self->majorGradiations >= 2;
        return unless $self->minorGradiations >= 2;
        return $self->addXPointSeries(
            id => 'feint-x',
            step => $self->xx($self->gridSpacingX) / ($self->majorGradiations * $self->minorGradiations),
            origin => $self->minorGridX->computedOrigin,
        );
    }
);

has majorGridY => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addYPointSeries(
            id => 'major-y',
            step => $self->gridSpacingY,
            canShiftPoints => 1,
        );
    }
);
has minorGridY => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return unless $self->majorGradiations >= 2;
        return $self->addYPointSeries(
            id => 'minor-y',
            step => $self->yy($self->gridSpacingY) / ($self->majorGradiations),
            origin => $self->majorGridY->computedOrigin,
        );
    }
);
has feintGridY => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return unless $self->majorGradiations >= 2;
        return unless $self->minorGradiations >= 2;
        return $self->addYPointSeries(
            id => 'feint-y',
            step => $self->yy($self->gridSpacingY) / ($self->majorGradiations * $self->minorGradiations),
            origin => $self->minorGridY->computedOrigin,
        );
    }
);

sub draw {
    my ($self) = @_;
    $self->majorGridX->compute();
    $self->majorGridY->compute();
    $self->minorGridX->compute();
    $self->minorGridY->compute();
    $self->feintGridX->compute();
    $self->feintGridY->compute();
    $self->startSVG();
    if ($self->majorGradiations) {
        if ($self->minorGradiations) {
            $self->drawGrid(
                groupId => 'feint',
                x => $self->feintGridX,
                y => $self->feintGridY,
                lineType => $self->feintLineType
            );
        }
        $self->drawGrid(
            groupId => 'minor',
            x => $self->minorGridX,
            y => $self->minorGridY,
            lineType => $self->minorLineType
        );
    }
    $self->drawGrid(
        groupId => 'major',
        x => $self->majorGridX,
        y => $self->majorGridY,
        lineType => $self->majorLineType
    );
    $self->endSVG();
}

1;
