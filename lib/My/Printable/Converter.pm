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

has 'dryRun'  => (is => 'rw', default => 0);
has 'verbose' => (is => 'rw', default => 0);
has 'width'   => (is => 'rw', default => 0);
has 'height'  => (is => 'rw', default => 0);

sub convertSVGToPDF {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            # realpath needed for inkscape on darwin (aka macOS)
            my ($from, $temp) = ($fromFilename, $tempFilename);
            if ($^O =~ m{^darwin}) {
                $from = realpath($from);
                $temp = realpath($temp);
            }
            my $cmd = sprintf(
                "%s --export-dpi=600 --export-pdf=%s", $from, $temp
            );
            if ($self->dryRun) {
                print STDERR ("would pass to inkscape shell:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ passing to Inkscape shell:\n    $cmd\n");
            }
            $self->inkscapeShell->cmd($cmd);
        }
    );
}

sub convertSVGToPS {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            # realpath needed for inkscape on darwin (aka macOS)
            my $cmd = sprintf(
                "%s --export-dpi=600 --export-ps=%s",
                shell_quote(realpath($fromFilename)),
                shell_quote(realpath($tempFilename)),
            );
            if ($self->dryRun) {
                print STDERR ("would pass to inkscape shell:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ passing to Inkscape shell:\n    $cmd\n");
            }
            $self->inkscapeShell->cmd($cmd);
        }
    );
}

sub convertPDFTo2UpPDF {
    my ($self, $fromFilename, $toFilename) = @_;
    my $pdfnup = $self->pdfnupLocation;
    if (!$pdfnup) {
        die("pdfnup program not found\n");
    }
    my $inputWidth = $self->width;
    my $inputHeight = $self->height;
    my $outputWidth = $inputHeight;
    my $outputHeight = 2 * $inputWidth;
    my $papersize = sprintf('{%.3fbp,%.3fbp}', $outputWidth, $outputHeight);
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                'pdfnup --no-tidy --outfile %s --papersize %s --nup 2x1 %s 1,1',
                shell_quote($tempFilename),
                shell_quote($papersize),
                shell_quote($fromFilename),
            );
            if ($self->dryRun) {
                print STDERR ("would convert PDF to two-up PDF:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ converting PDF to two-up PDF:\n    $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempFilename);
                die("pdfbook failed; exiting\n");
            }
        }
    );
}

sub convertPDFToNUpPDF {
    # stub
    # for 2-up or 4-up
}

sub convert2PagePSTo2UpPS {
    my ($self, $fromFilename, $toFilename) = @_;
    if (!which('pdfbook')) {
        die("pdfbook program not found\n");
    }
    my $inputWidth = $self->width;
    my $inputHeight = $self->height;
    my $outputWidth = $inputHeight;
    my $outputHeight = 2 * $inputWidth;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                'psnup -w%g -h%g -W%g -H%g -m0 -b0 -d0 -s1 -2 %s %s',
                $outputWidth,
                $outputHeight,
                $inputWidth,
                $inputHeight,
                $fromFilename,
                $tempFilename,
            );
            if ($self->dryRun) {
                print STDERR ("would convert two-page PS to two-up PS:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ converting two-page PS to two-up PS:\n    $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempFilename);
                die("psnup failed; exiting\n");
            }
        }
    );
}

sub convertPSToNUpPS {
    # stub
    # for 2-up or 4-up.
    # need to use IPC::Run or something.
}

sub convertPDFTo2PagePDF {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            if ($self->dryRun) {
                print STDERR ("would convert 1-page PDF to 2-page PDF via PDF::API2:\n    $fromFilename => $tempFilename\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("Converting 1-page PDF to 2-page PDF via PDF::API2:\n    $fromFilename => $tempFilename\n");
            }
            my $inputPDF = PDF::API2->open($fromFilename);
            my $outputPDF = PDF::API2->new();
            $outputPDF->import_page($inputPDF, 1, 0);
            $outputPDF->import_page($inputPDF, 1, 0);
            $outputPDF->saveas($tempFilename);
        }
    );
}

sub convertPSTo2PagePS {
    my ($self, $fromFilename, $toFilename) = @_;
    if (!which('psselect')) {
        die("psselect program not found");
    }
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                'psselect 1,1 %s %s',
                shell_quote($fromFilename),
                shell_quote($tempFilename),
            );
            if ($self->dryRun) {
                print STDERR ("would convert one-page PS to two-page PS:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ converting one-page PS to two-page PS:\n    $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempFilename);
                die("psselect failed; exiting\n");
            }
        }
    );
}

sub convert2PagePDFTo2Page2UpPDF {
    my ($self, $fromFilename, $toFilename) = @_;
    if (!which('pdfbook')) {
        die("pdfbook program not found\n");
    }
    my $inputWidth = $self->width;
    my $inputHeight = $self->height;
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
            if ($self->dryRun) {
                print STDERR ("would convert two-page PDF to two-page two-up PDF:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ converting two-page PDF to two-page two-up PDF:\n    $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempFilename);
                die("pdfbook failed; exiting\n");
            }
        }
    );
}

sub convertPDFTo2PageNUpPDF {
    # stub
    # for 2-up or 4-up.
    # need to use IPC::Run or something.
}

sub convertPSTo2PageNUpPS {
    # stub
    # for 2-up or 4-up.
    # need to use IPC::Run or something.
}

sub convertPDFToPS {
    my ($self, $fromFilename, $toFilename) = @_;
    with_temp(
        $toFilename, sub {
            my ($tempFilename) = @_;
            my $cmd = sprintf(
                "pdftops %s %s",
                shell_quote($fromFilename),
                shell_quote($tempFilename),
            );
            if ($self->dryRun) {
                print STDERR ("would convert PDF to PS:\n    $cmd\n");
                return -1;
            }
            if ($self->verbose) {
                print STDERR ("+ converting PDF to PS:\n    $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempFilename);
                die("psjoin failed; exiting\n");
            }
        }
    );
}

# can't just run which('pdfnup') because there's a python library that
# installs a completely unrelated 'pdfnup' script.  We want the one
# that comes with pdfjam.
has 'pdfnupLocation' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my @paths = which('pdfnup');
        push(@paths, grep { -e $_ } (
            '/usr/local/share/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/local/share/texlive/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/share/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/share/texlive/texmf-dist/scripts/pdfjam/pdfnup',
        ));
        foreach my $path (@paths) {
            my $shebang = $self->getShebangFromFile($path);
            if ($shebang eq 'bash' || $shebang eq 'sh') {
                return $path;
            }
        }
        return undef;
    }
);

sub getShebangFromFile {
    my ($self, $path) = @_;
    local $/ = "\n";
    my $fh;
    open($fh, '<', $path) or return;
    my $shebang = <$fh>;
    $shebang =~ s{\R\z}{};
    close($fh);
    if ($shebang =~ m{^\s*\#\s*\!\s*\S*/([^\/]+)(?:$|\s)}) {
        return $1;
    }
    return;
}

1;
