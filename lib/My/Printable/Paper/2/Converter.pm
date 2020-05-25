package My::Printable::Paper::2::Converter;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Paper::2::InkscapeShell;

use File::Path qw(make_path);
use File::Basename qw(dirname);
use String::ShellQuote qw(shell_quote);
use Cwd qw(realpath);
use File::Which qw(which);
use IPC::Run qw(run);
use PDF::API2;

use Moo;

use vars qw($useInkscapeShell);

BEGIN {
    $useInkscapeShell = 1;
}

has paper => (is => 'rw');
has inkscapeShell => (
    is => 'rw', lazy => 1, default => sub {
        return globalInkscapeShell();
    },
);
has verbose => (is => 'rw', default => 0);
has useInkscapeShell => (
    is => 'rw', default => sub {
        return $useInkscapeShell;
    }
);

sub globalInkscapeShell {
    state $inkscapeShell;
    return $inkscapeShell ||= My::Printable::Paper::2::InkscapeShell->new();
}

sub exportSVG {
    my $self = shift;
    my $from = shift;
    my $to = shift;
    my $format;
    if ($to =~ m{\.pdf\z}i) {
        $format = 'pdf';
    } elsif ($to =~ m{\.ps\z}i) {
        $format = 'ps';
    } else {
        die("exportSVGTo: only pdf and ps supported");
    }
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my ($from, $to) = ($from, $to);
            if ($^O =~ m{^darwin}) {
                $from = realpath($from);
                $temp = realpath($temp);
                $to   = realpath($to);
            }
            if ($self->useInkscapeShell) {
                my $cmd = sprintf(
                    "%s --export-dpi=600 --export-file=%s",
                    shell_quote($from),
                    shell_quote($temp),
                );
                $self->inkscapeShell->verbose($self->verbose);
                $self->inkscapeShell->cmd($cmd);
            } else {
                my $cmd = ['inkscape',
                           $from,
                           sprintf('--export-file=%s', $temp)];
                my $status = run $cmd;
                if (!$status) {
                    unlink($temp);
                }
            }
        }
    );
}

sub convertPDF {
    my $self = shift;

    my ($from, $to, $nUp, $nPages) = @_;
    if ($to eq $from || ($nUp == 1 && $nPages == 1)) {
        return;
    }
    return $self->convertPDFNpage($from, $to, $nPages) if $nUp == 1;
    return $self->convertPDF2upNpage($from, $to, $nPages) if $nUp == 2;
    return $self->convertPDF4upNpage($from, $to, $nPages) if $nUp == 4;
}

sub convertPS {
    my $self = shift;

    my ($from, $to, $nUp, $nPages) = @_;
    if ($to eq $from || ($nUp == 1 && $nPages == 1)) {
        return;
    }
    return $self->convertPSNpage($from, $to, $nPages) if $nUp == 1;
    return $self->convertPS2upNpage($from, $to, $nPages) if $nUp == 2;
    return $self->convertPS4upNpage($from, $to, $nPages) if $nUp == 4;
}


sub convertPDFNpage {
    my $self = shift;

    my ($from, $to, $nPages) = @_;
    if ($nPages < 2) {
        return;
    }
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $inputPDF = PDF::API2->open($from);
            my $outputPDF = PDF::API2->new();
            foreach my $i (1 .. $nPages) {
                $outputPDF->import_page($inputPDF, 1, 0);
            }
            $outputPDF->saveas($temp);
        }
    );
}

sub convertPSNpage {
    my $self = shift;

    my ($from, $to, $nPages) = @_;
    if ($nPages < 2) {
        return;
    }
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $pages = join(',', ('1' x $nPages));
            my $cmd = sprintf(
                'psselect %s %s %s',
                shell_quote($pages),
                shell_quote($from),
                shell_quote($temp),
            );
            if (system($cmd)) {
                unlink($temp);
            }
        }
    );
}

sub convertPDF2upNpage {
    my $self = shift;

    my ($from, $to, $nPages) = @_;
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $inputPDF = PDF::API2->open($from);
            my $outputPDF = PDF::API2->new();
            my $inputWidth = $self->paper->xx('width');
            my $inputHeight = $self->paper->yy('height');
            my $outputWidth  = $inputHeight;
            my $outputHeight = 2 * $inputWidth;
            foreach my $page (0 .. ($nPages - 1)) {
                my $outputPage = $outputPDF->page();
                $outputPage->mediabox(0, 0, $outputWidth, $outputHeight);
                my $xo = $outputPDF->importPageIntoForm($inputPDF, 1);

                # for printing with long edge binding
                my $gfx = $outputPage->gfx();
                if ($page % 2) {
                    # even page
                    $gfx->rotate(90);
                    $gfx->formimage($xo, $inputWidth, -$inputHeight, 1);
                    $gfx->formimage($xo, 0, -$inputHeight, 1);
                } else {
                    # odd page
                    $gfx->rotate(270);
                    $gfx->formimage($xo, -$inputWidth, 0, 1);
                    $gfx->formimage($xo, -2 * $inputWidth, 0, 1);
                }
            }
            $outputPDF->saveas($temp);
        }
    );
}

sub convertPS2upNpage {
    my $self = shift;

    my @fail;
    if (!which('pstops')) {
        push(@fail, 'pstops utility not installed');
    }
    if (!which('psselect')) {
        push(@fail, 'psselect utility not installed');
    }
    if (scalar @fail) {
        die(join('; ', @fail) . "\n");
    }

    my ($from, $to, $nPages) = @_;
    my $inputWidth = $self->paper->xx('width');
    my $inputHeight = $self->paper->yy('height');
    my $outputWidth  = $inputHeight;
    my $outputHeight = 2 * $inputWidth;
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $pages = join(',', ('1,1' x $nPages));
            my $psselect = ['psselect', $pages, $from];
            my $spec;
            if ($nPages == 1) {
                $spec = '2:0L(1h,0)+1L(1h,1w)';
            } elsif ($nPages == 2) {
                $spec = '4:0L(1h,0)+1L(1h,1w),2R(0,1w)+3R(0,2w)';
            } else {
                $spec = sprintf('%d:', $nPages * 2);
                my @spec = ();
                foreach my $page (0 .. $nPages) {
                    if ($page % 2 == 0) {
                        push(@spec, '%dL(1h,0)+%dL(1h,1w)', $nPages * 2, $nPages * 2 + 1);
                    } else {
                        push(@spec, '%dR(0,1w)+%dR(0,2w)', $nPages * 2, $nPages * 2 + 1);
                    }
                }
                $spec .= join(',', @spec);
            }
            my $pstops = ['pstops',
                          sprintf('-w%g', $outputWidth),
                          sprintf('-h%g', $outputHeight),
                          $spec];
            my $status = run $psselect, '|', $pstops, '>', $temp;
            if (!$status) {
                unlink($temp);
            }
        }
    );
}

sub convertPDF4upNpage {
    my $self = shift;

    my ($from, $to, $nPages) = @_;
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $inputPDF = PDF::API2->open($from);
            my $outputPDF = PDF::API2->new();
            my $inputWidth = $self->paper->xx('width');
            my $inputHeight = $self->paper->yy('height');
            my $outputWidth = 2 * $inputWidth;
            my $outputHeight = 2 * $inputHeight;
            foreach my $page (0 .. ($nPages - 1)) {
                my $outputPage = $outputPDF->page();
                $outputPage->mediabox(0, 0, $outputWidth, $outputHeight);
                my $xo = $outputPDF->importPageIntoForm($inputPDF, 1);

                # for printing with long edge binding
                my $gfx = $outputPage->gfx();
                $gfx->formimage($xo, 0, $inputHeight, 1);
                $gfx->formimage($xo, $inputWidth, $inputHeight, 1);
                $gfx->rotate(180);
                $gfx->formimage($xo, -$inputWidth, -$inputHeight, 1);
                $gfx->formimage($xo, -2 * $inputWidth, -$inputHeight, 1);
            }
            $outputPDF->saveas($temp);
        }
    );
}

sub convertPS4upNpage {
    my $self = shift;

    my @fail;
    if (!which('pstops')) {
        push(@fail, 'pstops utility not installed');
    }
    if (!which('psselect')) {
        push(@fail, 'psselect utility not installed');
    }
    if (scalar @fail) {
        die(join('; ', @fail) . "\n");
    }

    my ($from, $to, $nPages) = @_;
    my $inputWidth = $self->paper->xx('width');
    my $inputHeight = $self->paper->yy('height');
    my $outputWidth  = 2 * $inputWidth;
    my $outputHeight = 2 * $inputHeight;
    $self->tempFileOperation(
        $to, sub {
            my $temp = shift;
            my $pages = join(',', ('1,1,1,1' x $nPages));
            my $psselect = ['psselect', $pages, $from];
            my $spec = '4:0(0,1h)+1(1w,1h)+2U(1w,1h)+3U(2w,1h)';
            my $pstops = ['pstops',
                          sprintf('-w%g', $outputWidth),
                          sprintf('-h%g', $outputHeight),
                          $spec];
            my $status = run $psselect, '|', $pstops, '>', $temp;
            if (!$status) {
                unlink($temp);
            }
        }
    );
}

sub tempFileOperation {
    my $self = shift;

    my $filename = shift;
    my $sub = shift;
    my $tempname = $self->tempFilename($filename);
    make_path(dirname($tempname));
    if (-e $tempname && !unlink($tempname)) {
        die("cannot unlink $tempname: $!");
    }
    print STDERR ("Writing $filename ...\n");
    my $result = $sub->($tempname);
    if (!-e $tempname) {
        die("$tempname was not created");
    }
    if (!rename($tempname, $filename)) {
        die("rename $tempname to $filename failed: $!");
    }
}

sub tempFilename {
    my $self = shift;

    my $filename = shift;
    my $tempname = $filename;
    if ($tempname =~ m{(?![^\.\\\/])(\.[^\.\/\\]+)$}x) {
        $tempname .= ".tmp" . $1;
    } else {
        $tempname .= ".tmp";
    }
    return $tempname;
}

1;
