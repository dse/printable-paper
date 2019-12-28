package My::Printable::Paper::2::Paper::FrenchRuled;
use warnings;
use strict;
use v5.10.0;

use Moo;

extends 'My::Printable::Paper::2::Paper';

has 'gridSpacing'          => (is => 'rw', default => '8mm');
has 'leftMarginLine'       => (is => 'rw', default => '41mm from left');
has 'topHorizontalLine'    => (is => 'rw', default => '37mm from top');
has 'bottomHorizontalLine' => (is => 'rw', default => '28mm from bottom');
has 'feintLines'           => (is => 'rw', default => 4);
has 'topHorizontalLineFeint' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->yy($self->topHorizontalLine) - ($self->feintLines - 1) * $self->yy($self->gridSpacing) / $self->feintLines;
    }
);
has 'bottomHorizontalLineFeint' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->yy($self->bottomHorizontalLine) + ($self->feintLines - 2) * $self->yy($self->gridSpacing) / $self->feintLines;
    }
);

has 'horizontalLineTypeA' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'ha',
            width => '5.6pd',
        );
    }
);
has 'horizontalLineTypeB' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'hb',
            width => '4pd',
        );
    }
);
has 'verticalLineType' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'va',
            width => '4pd',
        );
    }
);
has 'marginLineType' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addLineType(
            id => 'm',
            width => '5.6pd',
            stroke => 'red',
        );
    }
);
has 'gridX' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addXPointSeries(
            id => 'gx',
            origin => $self->leftMarginLine,
            step => $self->gridSpacing,
        );
    }
);
has 'gridY' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addYPointSeries(
            id => 'gy',
            origin => $self->topHorizontalLine,
            from => $self->topHorizontalLine,
            to => $self->bottomHorizontalLine,
            step => $self->gridSpacing,
        );
    }
);
has 'feintGridY' => (
    is => 'rw', lazy => 1, default => sub {
        my ($self) = @_;
        return $self->addYPointSeries(
            id => 'fgy',
            step => $self->yy($self->gridSpacing) / $self->feintLines,
            origin => $self->gridY->computedOrigin,
            from => $self->topHorizontalLineFeint,
            to => $self->bottomHorizontalLineFeint,
        );
    }
);

sub draw {
    my ($self) = @_;
    $self->startSVG();

    $self->gridX->compute();
    $self->gridY->compute();
    $self->feintGridY->compute();

    say $self->gridX->toString;
    say $self->gridY->toString;
    say $self->feintGridY->toString;

    $self->drawHorizontalLines(
        groupId => 'ha',
        y => $self->gridY,
        lineType => $self->horizontalLineTypeA,
    );
    $self->drawHorizontalLines(
        groupId => 'hb',
        y => $self->feintGridY,
        lineType => $self->horizontalLineTypeB,
    );
    $self->drawVerticalLines(
        groupId => 'v',
        x => $self->gridX,
        lineType => $self->verticalLineType,
    );
    $self->drawVerticalLines(
        groupId => 'm',
        x => $self->leftMarginLine,
        lineType => $self->marginLineType,
    );

    $self->endSVG();
}

1;
