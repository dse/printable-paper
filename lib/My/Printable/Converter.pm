package My::Printable::Converter;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Util::InkscapeShell;
use My::Printable::Util qw(with_temp);

use String::ShellQuote qw(shell_quote);
use Cwd qw(realpath getcwd);
use File::Path qw(make_path);
use File::Basename qw(dirname basename);
use File::Find qw(find);
use Text::Trim qw(trim);
use Getopt::Long qw();
use Data::Dumper qw(Dumper);
use Storable qw(dclone);
use PDF::API2 qw();
use File::Which qw(which);

use Moo;

has 'inkscapeShell' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        if (!which('inkscape')) {
            die("inkscape progran not found\n");
        }
        return My::Printable::Util::InkscapeShell->new();
    },
);

sub svgToPDF {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            make_path(dirname($tempFilename));
            unlink($tempFilename);
            # realpath needed for inkscape on darwin (aka macOS)
            my $cmd = sprintf(
                "%s --export-dpi=600 --export-pdf %s",
                shell_quote(realpath($fromFilename)),
                shell_quote(realpath($tempFilename)),
            );
            $self->inkscapeShell->cmd($cmd);
        }
    );
}

sub svgToPS {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            make_path(dirname($tempFilename));
            unlink($tempFilename);
            # realpath needed for inkscape on darwin (aka macOS)
            my $cmd = sprintf(
                "%s --export-dpi=600 --export-ps=%s",
                shell_quote(realpath($fromFilename)),
                shell_quote(realpath($tempFilename)),
            );
            $self->inkscapeShell->cmd($cmd);
        }
    );
}

sub pdfToTwoPagePDF {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $inputPDF = PDF::API2->open($fromFilename);
            my $outputPDF = PDF::API2->new();
            $outputPDF->import_page($inputPDF, 1, 0);
            $outputPDF->import_page($inputPDF, 1, 0);
            $outputPDF->saveas($tempFilename);
        }
    );
}

sub psToTwoPagePS {
    my ($self, $fromFilename, $toFilename) = @_;
    if (!which('psselect')) {
        die("psselect program not found");
    }
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                "psjoin %s %s >%s",
                shell_quote($fromFilename),
                shell_quote($fromFilename),
                shell_quote($tempFilename),
            );
            if (system($cmd)) {
                unlink($tempFilename);
                die("psjoin failed; exiting\n");
            }
        }
    );
}

sub pdfToTwoUpPDF {
    my ($self, $fromFilename, $toFilename) = @_;
    my ($inputWidth, $inputHeight) = $self->getPDFSize($fromFilename);
    if (!which('pdfbook')) {
        die("pdfbook program not found\n");
    }
    my $outputWidth = $inputHeight;
    my $outputHeight = 2 * $inputWidth;
    my $papersize = sprintf('{%.3fbp,%.3fbp}', $outputWidth, $outputHeight);
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                "pdfbook --no-tidy --outfile %s --papersize %s --nup 2x1 --twoside %s 1,2,1,2",
                shell_quote($tempFilename),
                shell_quote($papersize),
                shell_quote($fromFilename),
            );
            if (system($cmd)) {
                unlink($tempFilename);
                die("pdfbook failed; exiting\n");
            }
        }
    );
}

sub pdfToPS {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                "pdftops %s %s",
                shell_quote($fromFilename),
                shell_quote($tempFilename),
            );
            if (system($cmd)) {
                unlink($tempFilename);
                die("psjoin failed; exiting\n");
            }
        }
    );
}

sub getPDFSize {
    my ($self, $filename) = @_;
    my $pdf = PDF::API2->open($filename);
    my $page = $pdf->openpage(1);
    my ($llx, $lly, $urx, $ury) = $page->get_mediabox;
    my $width = $urx - $llx;
    my $height = $ury - $lly;
    return ($width, $height);
}

1;
