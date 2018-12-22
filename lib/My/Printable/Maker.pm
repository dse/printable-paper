package My::Printable::Maker;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/printable-paper/lib";
use My::Printable::Document;
use My::Printable::Ruling;
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
use File::Which;

use constant USE_OLD_FILENAMES => 1;

# sometimes yields an extra blank first page.
use constant USE_PDFXUP => 0;

# doesn't work well except with A series paper sizes.
# and doesn't resize. (i.e., a5 -> a4, halfletter -> letter)
use constant USE_PYTHON_PDFNUP => 0;

use constant USE_EXTERNAL_BIN_PRINTABLE => 0;
use constant USE_INKSCAPE_SHELL => 1;
use constant USE_PDF_API2 => 1;

use Moo;

has 'verbose'             => (is => 'rw', default => 0);
has 'dryRun'              => (is => 'rw', default => 0);
has 'force'               => (is => 'rw', default => 0);
has 'templatesArray'      => (is => 'rw', default => sub { return []; });
has 'perlModulesArray'    => (is => 'rw', default => sub { return []; });
has 'projectRoot'         => (is => 'rw');
has 'buildHashByFilename' => (is => 'rw', default => sub { return {}; });
has 'buildsArray'         => (is => 'rw', default => sub { return []; });

sub BUILD {
    my ($self) = @_;
    $self->buildTemplatesArray();
    $self->getPerlModulesArray();
}

sub run {
    my ($self, @args) = @_;
    my $operation = 'MAKE';
    my @buildsToPerform;
    my @filters;
    my $canDoAllBuilds = 1;
    foreach my $arg (@args) {
        if ($arg eq 'LIST' || $arg eq 'CLEAN' || $arg eq 'MAKE') {
            $operation = $arg;
        } else {
            if ($arg =~ m{[\.\/\\]}) {
                $canDoAllBuilds = 0;
                my $build = $self->buildHashByFilename->{$arg};
                if ($build) {
                    push(@buildsToPerform, $build);
                } else {
                    warn("Don't know how to make $arg.\n");
                }
            } else {
                my $arg = $arg;
                my $sub = sub {
                    return 1 if EQ($_->{template}->{ruling},     $arg);
                    return 1 if EQ($_->{template}->{size},       $arg);
                    return 1 if EQ($_->{file}->{type},           $arg);
                    return 1 if EQ($_->{file}->{filename},       $arg);
                    return 1 if EQ($_->{template}->{color_type}, $arg);
                    return 1 if EQ($_->{file}->{subtype},        $arg);
                    return 1 if $_->{file}->{filename} =~ m{ (^|/) \Q$arg\E ($|/) }xi;
                    my $modifiers = $_->{template}->{modifiers};
                    if ($modifiers && ref $modifiers eq 'ARRAY' && scalar @$modifiers) {
                        return 1 if grep { $_ eq $arg } @$modifiers;
                    }
                    return 0;
                };
                if ($arg =~ s{^[\!\-\^]}{}) {
                    push(@filters, sub {
                             @buildsToPerform = grep { !$sub->() } @buildsToPerform;
                         });
                } else {
                    push(@filters, sub {
                             @buildsToPerform = grep { $sub->() } @buildsToPerform;
                         });
                }
            }
        }
    }

    if (!scalar @buildsToPerform) {
        if (!$canDoAllBuilds) {
            warn("Nothing to do.  Exiting.\n");
            exit(0);
        }
        @buildsToPerform = @{$self->buildsArray};
    }

    foreach my $filter (@filters) {
        $filter->();
    }

    $self->chdirProjectRoot();

    if ($operation eq 'LIST') {
        foreach my $build (@buildsToPerform) {
            my $filename = $build->{file}->{filename};
            say $filename;
        }
        exit 0;
    } elsif ($operation eq 'MAKE') {
        if (!scalar @buildsToPerform) {
            if ($self->verbose) {
                warn("Nothing to build.\n");
            }
            exit(1);
        }
        if ($self->verbose) {
            warn("Will build:\n");
            foreach my $build (@buildsToPerform) {
                my $filename = $build->{file}->{filename};
                warn("- $filename\n");
            }
        }
        foreach my $build (@buildsToPerform) {
            my $filename = $build->{file}->{filename};
            if ($self->verbose) {
                warn("Building $filename...\n");
            }
            $self->build($filename);
        }
    } elsif ($operation eq 'CLEAN') {
        foreach my $build (@buildsToPerform) {
            my $filename = $build->{file}->{filename};
            if (-e $filename) {
                warn(sprintf("+ rm %s\n", shell_quote($filename)));
                if (!unlink($filename)) {
                    warn("Cannot unlink $filename: $!\n");
                }
            }
        }
    }
}

our @SIZES = (
    { size => 'letter' },
    { size => 'a4' },
    { size => 'halfletter', '2up' => 'letter' },
    { size => 'a5',         '2up' => 'a4'     },
);

our @COLLECTIONS = (
    {
        ruling => 'oasis',
        sizes => [@SIZES],
        variants => [
            [qw()],
            [qw(denser-grid)],
        ],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'anode',
        sizes => [@SIZES],
        variants => [
            [qw()],
            [qw(denser-grid)],
        ],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'quadrille',
        sizes => [@SIZES],
        variants => [
            [qw()],
            [qw(5-per-inch)],
        ],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'line-dot-grid',
        sizes => [@SIZES],
        variants => [
            [qw()],
            { name => 'thinner',   modifiers => [qw(thinner-dots thinner-lines)]     },
            { name => 'x-thinner', modifiers => [qw(x-thinner-dots x-thinner-lines)] },
        ],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'seyes',
        sizes => [@SIZES],
        variants => [
            { modifiers => []                            },
            { modifiers => [qw(thinner-grid)]            },
            { modifiers => [qw(three-line)]              },
            { modifiers => [qw(three-line thinner-grid)] },
        ],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'dot-grid',
        sizes => [@SIZES],
        color_types => ['color', 'black'],
    },
    {
        ruling => 'line-dot-graph',
        sizes => [@SIZES],
        color_types => ['color', 'black'],
    },
);

sub buildSVG {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};

    my $id = basename($target);
    $id =~ s{(?!^)\.[^\.]+$}{}; # remove extension
    $id =~ s{[^A-Za-z0-9\_\-\.]+}{}g; # remove anything except A-Z a-z 0-9 _ - .

    my @modifiers = (eval { @{$template->{modifiers}} },
                     eval { @{$file->{modifiers}} });

    if (USE_EXTERNAL_BIN_PRINTABLE) {
        my $cmd = sprintf("bin/printable -M %s", shell_quote($template->{size}));
        $cmd .= ' --black'     if $template->{color_type} eq 'black';
        $cmd .= ' --grayscale' if $template->{color_type} eq 'grayscale';
        $cmd .= sprintf(' --id=%s', shell_quote($id));
        $cmd .= sprintf(' --filename=%s', shell_quote($target));
        foreach my $modifier (@modifiers) {
            $cmd .= sprintf(" --modifier=%s", shell_quote($modifier));
        }
        $cmd .= sprintf(" %s >{FILENAME}", shell_quote($template->{ruling}));
        $self->cmd($target, $cmd);
    } else {
        with_temp(
            $target, sub {
                my ($tempname) = @_;
                my $ruling_class_name = My::Printable::Ruling->getRulingClassName($template->{ruling});
                eval "use $ruling_class_name";
                if ($@) {
                    die $@;
                }
                my $ruling = $ruling_class_name->new();
                $ruling->id($id);
                $ruling->paperSizeName($template->{size});
                $ruling->colorType($template->{color_type});
                $ruling->modifiers->set(@modifiers);
                $ruling->generate();
                $ruling->printToFile($tempname);
            }
        );
    }
}

has 'inkscapeShell' => (is => 'rw');

sub buildPDFFromSVG {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};
    if (!which('inkscape')) {
        die("inkscape program not found\n");
    }
    if (USE_INKSCAPE_SHELL) {
        if (!defined $self->inkscapeShell) {
            $self->inkscapeShell(My::Printable::Util::InkscapeShell->new());
        }
        with_temp(
            $target,
            sub {
                my ($tempname) = @_;
                make_path(dirname($tempname));
                unlink($tempname);
                $self->inkscapeShell->cmd(sprintf("%s --export-dpi=600 --export-pdf %s",
                                                  shell_quote($self->getPathForInkscape($dependencies->[0])),
                                                  shell_quote($self->getPathForInkscape($tempname))));
            }
        );
    } else {
        # svg2pdf will not work
        # rsvg-convert does not work, output looks like shit
        # imagenagick works but is not fast and rasterizes
        my $cmd = sprintf("inkscape --without-gui %s --export-dpi=600 --export-pdf {FILENAME}",
                          shell_quote($self->getPathForInkscape($dependencies->[0])));
        $self->cmd($target, $cmd);
    }
}

sub buildPSFromSVG {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};
    if (!which('inkscape')) {
        die("inkscape program not found\n");
    }
    if (USE_INKSCAPE_SHELL) {
        if (!defined $self->inkscapeShell) {
            $self->inkscapeShell(My::Printable::Util::InkscapeShell->new());
        }
        with_temp(
            $target,
            sub {
                my ($tempname) = @_;
                make_path(dirname($tempname));
                unlink($tempname);
                $self->inkscapeShell->cmd(sprintf("%s --export-background=transparent --export-ps=%s",
                                                  shell_quote($self->getPathForInkscape($dependencies->[0])),
                                                  shell_quote($self->getPathForInkscape($tempname))));
            }
        );
    } else {
        my $cmd = sprintf("inkscape --without-gui --export-dpi=300 --export-ps {FILENAME} %s",
                          shell_quote($self->getPathForInkscape($dependencies->[0])));
        $self->cmd($target, $cmd);
    }
}

sub build2PagePDF {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};
    if (USE_PDF_API2) {
        my @source_pdf = map { PDF::API2->open($_) } @$dependencies;
        if (scalar @$dependencies == 1) {
            my $pdf = PDF::API2->new();
            $pdf->import_page($source_pdf[0], 1, 0);
            $pdf->import_page($source_pdf[0], 1, 0);
            $pdf->saveas($target);
        } else {
            my $pdf = PDF::API2->new();
            $pdf->import_page($source_pdf[0], 1, 0);
            $pdf->import_page($source_pdf[1], 1, 0);
            $pdf->saveas($target);
        }
    } else {
        # pdfunite is part of poppler
        if (!which('pdfunite')) {
            die("pdfunite program, part of poppler, not found\n");
        }
        my $cmd;
        if (scalar @$dependencies == 1) {
            # has no special even page
            $cmd = sprintf("pdfunite %s %s {FILENAME}",
                           shell_quote($dependencies->[0]),
                           shell_quote($dependencies->[0]));
        } else {
            # has a special even page
            $cmd = sprintf("pdfunite %s %s {FILENAME}",
                           shell_quote($dependencies->[0]),
                           shell_quote($dependencies->[1]));
        }
        $self->cmd($target, $cmd);
    }
}

sub build2PagePS {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};

    # consider using GSAPI

    my $cmd;
    if (scalar @$dependencies == 1) {
        if (!which('psselect')) {
            die("psselect program not found\n");
        }
        # has no special even page
        $cmd = sprintf("psselect 1,1 %s >{FILENAME}",
                       shell_quote($dependencies->[0]));
    } else {
        if (!which('psjoin')) {
            die("psjoin program not found\n");
        }
        # has a special even page
        $cmd = sprintf("psjoin %s %s >{FILENAME}",
                       shell_quote($dependencies->[0]),
                       shell_quote($dependencies->[1]));
    }

    $self->cmd($target, $cmd);
}

sub build2UpPDF {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};

    my $input_papersizename  = $template->{size};
    my $output_papersizename = $template->{"2up"}->{size};
    my $iops = "${input_papersizename},${output_papersizename}";
    my $can_use_pdfxup = 0;
    if ($iops eq 'halfletter,letter' || $iops eq 'a5,a4') {
        $can_use_pdfxup = 1;
    }

    if (USE_PYTHON_PDFNUP && (my $pdfnup = $self->findPdfnup(type => 'python'))) {
        # pip install pdfnup --install-option="--install-scripts=/usr/local/bin"
        # otherwise, overwrites a pdfjam /usr/bin/pdfnup executable.
        my @cmd = (
            $pdfnup
        );
        if (!-x $pdfnup) {
            unshift(@cmd, 'python');
        }
        push(@cmd, (
            '-n', '2',
            '-o', '{FILENAME}',
            $dependencies->[0]
        ));
        return $self->cmd($target, \@cmd);
    }

    if (USE_PDFXUP && $can_use_pdfxup && which('pdfxup')) {
        # pdfxup is faster but may not support all papersizes.
        local $ENV{dfpdfxupPAP} = $output_papersizename;
        my ($output_width_pt, $output_height_pt) = split(/\s+/, `paperconf -s $output_papersizename`);
        my $output_width_tex_pt  = $output_width_pt  / 72 * 72.27;
        my $output_height_tex_pt = $output_height_pt / 72 * 72.27;
        my $cmd = sprintf('pdfxup -b le -s 0 0 %.3f %.3f -im 0 -m 0 -is 0 -fw 0 -o {FILENAME} %s',
                          $output_width_pt,
                          $output_height_pt,
                          shell_quote($dependencies->[0]));
        return $self->cmd($target, $cmd);
    }

    if (which('pdfbook')) {
        # pdfbook is slow.  It is based on pdfjam.
        my ($input_width_pt,  $input_height_pt)  = split(/\s+/, `paperconf -s $input_papersizename`);
        my ($output_width_pt, $output_height_pt) = split(/\s+/, `paperconf -s $output_papersizename`);
        my $output_papersize = sprintf('{%.3fbp,%.3fbp}', $output_width_pt, $output_height_pt);
        my $cmd = sprintf("pdfbook --no-tidy --outfile {FILENAME} --papersize %s --nup 2x1 --twoside %s 1,2,1,2",
                          shell_quote($output_papersize),
                          shell_quote($dependencies->[0]));
        return $self->cmd($target, $cmd);
    }

    die("No pdf N-up utility found.  :-(\n");

    # NOTES: There's a Python script called pdfnup, and
    # something that comes with TeXlive called pdfnup, which
    # is based on pdfjam.

    # pdftk and qpdf do not offer N-up capability.
}

sub build2UpPS {
    my ($self, %args) = @_;
    my ($target, $dependencies, $template, $file, $build) = @args{qw(target dependencies template file build)};
    my $p = $dependencies->[0];
    my $cmd = sprintf("pdftops %s {FILENAME}", shell_quote($p));
    $self->cmd($target, $cmd);
}

our %BUILD = (
    svg => {
        dependencies => [qw(bin/printable makebin/makeprintable)],
        dependOnPerlModules => 1,
        forceIfApplicable => 1,
        code => \&buildSVG,
    },
    svg_pdf => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&buildPDFFromSVG,
    },
    svg_ps => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&buildPSFromSVG,
    },
    two_page_pdf => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&build2PagePDF,
    },
    two_page_ps => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&build2PagePS,
    },
    two_up_pdf => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&build2UpPDF,
    },
    two_up_ps => {
        dependencies => [qw(makebin/makeprintable)],
        code => \&build2UpPS,
    },
);

sub build {
    my ($self, $filename) = @_;
    foreach my $template (@{$self->templatesArray}) {
        foreach my $file (@{$template->{files}}) {
            if ($file->{filename} eq $filename) {
                $self->buildFile(
                    template => $template,
                    file     => $file
                );
                return;
            }
        }
    }
    die("Don't know how to build $filename.\n");
}

sub buildFile {
    my ($self, %args) = @_;
    my $template     = $args{template};
    my $file         = $args{file};
    my $target       = $file->{filename};
    my @dependencies = eval { @{$file->{dependencies}} };
    my $build        = $file->{build};
    my $forceIfApplicable = $build->{forceIfApplicable};

    my @build_dependencies = eval { @{$build->{dependencies}} };

    if ($build->{dependOnPerlModules}) {
        push(@build_dependencies, @{$self->perlModulesArray});
    }

    if ($self->verbose) {
        warn("$target requires:\n");
        warn("    dependencies       @dependencies\n") if scalar @dependencies;
        warn("    build dependencies @build_dependencies\n") if scalar @build_dependencies;
    }

    my $target_exists = -e $target;
    my $target_age    = -M _;

    my $make = 0;
    if ($forceIfApplicable && $self->force) {
        $make = 1;
    }
    if (!$target_exists) {
        $make = 1;
    }
    foreach my $dependency (@dependencies) {
        if (!-e $dependency) {
            $self->build($dependency);
            $make = 1;
        } else {
            $self->build($dependency);
            if ($target_exists && -M $dependency < $target_age) {
                $make = 1;
            }
        }
    }
    foreach my $dependency (@build_dependencies) {
        if ($target_exists && -M $dependency < $target_age) {
            $make = 1;
        }
    }

    if ($make) {
        if ($self->verbose >= 0) {
            warn("makeprintable: Building $target ...\n");
        }
        my $code = $build->{code};
        $self->$code(target => $target,
                     dependencies => \@dependencies,
                     template => $template,
                     file => $file,
                     build => $build);
    } else {
        if ($self->verbose >= 0) {
            warn("makeprintable: $target is up to date.\n");
        }
    }
}

sub chdirProjectRoot {
    my ($self) = @_;
    if (!defined $self->projectRoot) {
        my $progname = realpath($0);
        my $progdir = dirname($progname);
        chdir($progdir);
        my $projdir = trim(`git rev-parse --show-toplevel 2>/dev/null`);
        if ($? || !defined $projdir || $projdir !~ m{\S}) {
            die("not in a git project\n");
        }
        $self->projectRoot($projdir);
    }
    chdir($self->projectRoot);
}

sub buildTemplatesArray {
    my ($self) = @_;

    @{$self->templatesArray} = ();

    foreach my $collection (@COLLECTIONS) {
        my $ruling      = $collection->{ruling};
        my $sizes       = $collection->{sizes};
        my $variants    = $collection->{variants};
        my $color_types = $collection->{color_types} // ['color'];
        if (!$variants) {
            $variants = [
                { modifiers => [] },
            ];
        }
        foreach my $color_type (@$color_types) {
            foreach my $size (@$sizes) {
                my $size_name = (ref $size eq 'HASH') ? $size->{size}  : $size;
                my $size_2up  = (ref $size eq 'HASH') ? $size->{'2up'} : undef;
                foreach my $variant (@$variants) {
                    my $variant_modifiers =
                        ((ref $variant eq 'ARRAY') ? $variant :
                         (ref $variant eq 'HASH') ? $variant->{modifiers} :
                         undef) // [];
                    my $variant_name =
                        ((ref $variant eq 'HASH') ? $variant->{name} :
                         undef) // join('--', @$variant_modifiers);

                    my $base = $ruling;
                    $base .= '/' . $color_type;
                    $base .= '/' . $ruling;

                    if (USE_OLD_FILENAMES) {
                        if ($color_type ne 'color') {
                            $base .= '--' . $color_type;
                        }
                    } else {
                        $base .= '--' . $color_type;
                    }

                    if (USE_OLD_FILENAMES) {
                        if (defined $variant_name && $variant_name ne '') {
                            $base .= '--' . $variant_name;
                        }
                    }

                    $base .= '--' . $size_name;

                    if (!USE_OLD_FILENAMES) {
                        if (defined $variant_name && $variant_name ne '') {
                            $base .= '--' . $variant_name;
                        }
                    }

                    my $base_2up;
                    if ($size_2up) {
                        $base_2up = $base;
                        $base_2up .= '-2up-' . $size_2up;
                    }

                    my $template = {
                        base       => $base,
                        ruling     => $ruling,
                        color_type => $color_type,
                        size       => $size_name,
                        modifiers  => dclone($variant_modifiers),
                    };
                    if ($size_2up) {
                        $template->{'2up'} = {
                            'size' => $size_2up,
                        };
                        $template->{'base_2up'} = $base_2up;
                    }

                    push(@{$self->templatesArray}, $template);
                }
            }
        }
    }

    foreach my $template (@{$self->templatesArray}) {
        my $ruling = $template->{ruling};
        my $base = $template->{base};

        my $svg = "templates/svg/${base}.svg";
        my $pdf = "templates/pdf/${base}.pdf";
        my $ps  = "templates/ps/${base}.ps";

        my $svg_even_page = "templates/even-page-svg/${base}.evenpage.svg";
        my $pdf_even_page = "templates/even-page-pdf/${base}.evenpage.pdf";
        my $ps_even_page  = "templates/even-page-ps/${base}.evenpage.ps";

        my $pdf_2_page = "templates/2-page-pdf/${base}.2page.pdf";
        my $ps_2_page  = "templates/2-page-ps/${base}.2page.ps";

        my $pdf_2_page_dependencies = [$pdf];
        my $ps_2_page_dependencies  = [$ps];

        $template->{files} = [];

        push(@{$template->{files}}, { type => "svg", filename => $svg,                         build => $BUILD{svg}     });
        push(@{$template->{files}}, { type => "pdf", filename => $pdf, dependencies => [$svg], build => $BUILD{svg_pdf} });
        push(@{$template->{files}}, { type => "ps",  filename => $ps,  dependencies => [$svg], build => $BUILD{svg_ps}  });

        if ($template->{has_even_pages}) {
            push(@{$template->{files}}, { type => "svg", subtype => "even-page", filename => $svg_even_page,                                   build => $BUILD{svg},    modifiers => [qw(even-page)] });
            push(@{$template->{files}}, { type => "pdf", subtype => "even-page", filename => $pdf_even_page, dependencies => [$svg_even_page], build => $BUILD{svg_pdf} });
            push(@{$template->{files}}, { type => "ps",  subtype => "even-page", filename => $ps_even_page,  dependencies => [$svg_even_page], build => $BUILD{svg_ps}  });

            push(@$pdf_2_page_dependencies, $pdf_even_page);
            push(@$ps_2_page_dependencies,  $ps_even_page);
        }

        push(@{$template->{files}}, { type => "pdf", subtype => "2-page", filename => $pdf_2_page, dependencies => $pdf_2_page_dependencies, build => $BUILD{two_page_pdf} });
        push(@{$template->{files}}, { type => "ps",  subtype => "2-page", filename => $ps_2_page,  dependencies => $ps_2_page_dependencies,  build => $BUILD{two_page_ps}  });

        my $two_up_size = eval { $template->{"2up"}->{size} };
        if ($two_up_size) {
            my $two_up_base = eval { $template->{'base_2up'} };
            my $pdf_2_up = "templates/2-up-pdf/${two_up_base}.2up.pdf";
            my $ps_2_up  = "templates/2-up-ps/${two_up_base}.2up.ps";
            push(@{$template->{files}}, { type => "pdf", subtype => "2-up", filename => $pdf_2_up, dependencies => [$pdf_2_page], build => $BUILD{"two_up_pdf"} });
            push(@{$template->{files}}, { type => "ps",  subtype => "2-up", filename => $ps_2_up,  dependencies => [$pdf_2_up],   build => $BUILD{"two_up_ps"} });
        }
    }

    @{$self->buildsArray} = ();
    %{$self->buildHashByFilename} = ();

    foreach my $template (@{$self->templatesArray}) {
        foreach my $file (@{$template->{files}}) {
            my $filename = $file->{filename};
            my $build = {
                template => $template,
                file => $file
            };
            push(@{$self->buildsArray}, $build);
            $self->buildHashByFilename->{$filename} = $build;
        }
    }
}

sub getPathForInkscape {
    my ($self, $path) = @_;
    if ($^O =~ m{^darwin}) {
        return realpath($path);
    }
    return $path;
}

sub cmd {
    my ($self, $filename, $cmd) = @_;
    $filename = $self->getPathForInkscape($filename);
    if (ref $cmd && ref $cmd eq 'ARRAY') {
        $cmd = join(' ', map { shell_quote($_) } @$cmd);
    }
    with_temp(
        $filename,
        sub {
            my ($tempname) = @_;
            $cmd =~ s{\{FILENAME\}}{shell_quote($tempname)}ge;
            if ($self->verbose) {
                warn("+ $cmd\n");
            }
            if (system($cmd)) {
                unlink($tempname);
                die("command failed --- exiting.\n");
            }
        }
    );
}

sub getPerlModulesArray {
    my ($self) = @_;
    my $cwd = getcwd();
    $self->chdirProjectRoot();
    my @modules;
    my $wanted = sub {
        if (lstat($_) && -f _ && m{\.pm\z}) {
            push(@modules, $File::Find::name);
        }
    };
    find($wanted, '.');
    @{$self->perlModulesArray} = @modules;
    chdir($cwd);
}

sub findPdfnup {
    my ($self, %args) = @_;
    my $type = $args{type};

    my $cwd = getcwd();
    $self->chdirProjectRoot();

    state @paths;
    if (!scalar @paths) {
        @paths = which('pdfnup');
        push(
            @paths,
            '/usr/local/share/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/local/share/texlive/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/share/texmf-dist/scripts/pdfjam/pdfnup',
            '/usr/share/texlive/texmf-dist/scripts/pdfjam/pdfnup',
        );
    }

    state @syspath;
    if (!scalar @syspath) {
        @syspath = get_python_sys_path();
    }

    state @pdfnup;
    if (!scalar @pdfnup) {
        @pdfnup = grep { -e $_ } map { (
            "$_/EGG-INFO/scripts/pdfnup",
            "$_/pdfnup.py",
        ) } @syspath;
        push(@paths, @pdfnup);
    }

    state %pdfnup_type;

    foreach my $path (@paths) {
        my $pdfnup_type = $pdfnup_type{$path} //= get_pdfnup_type($path);
        if (!defined $pdfnup_type) {
            next;
        }
        if (defined $pdfnup_type && $pdfnup_type eq $type) {
            chdir($cwd);
            return $path;
        }
    }
    chdir($cwd);
    return;
}

sub getPdfnupType {
    my ($self, $path) = @_;
    my $shebang = $self->getShebangFromFile($path);
    if (!defined $shebang) {
        return;
    }
    if ($shebang eq 'sh' || $shebang eq 'bash') {
        return 'pdfjam';
    }
    if ($shebang eq 'python' || $shebang =~ m{^python-?\d}) {
        return 'python';
    }
    return;
}

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

sub getPythonSysPath {
    my ($self) = @_;
    my $ph;
    my $script = <<"END";
import sys
for component in sys.path:
    print(component)
END
    local $/ = "\n";
    local $_;
    open($ph, '-|', 'python', '-c', $script) or return;
    my @path;
    while (<$ph>) {
        s{\R\z}{};
        push(@path, $_) if $_ =~ m{\S};
    }
    close($ph);
    return @path;
}

# returns true if both arguments are `eq` equal, or both are
# undefined.
sub EQ {
    my ($a, $b) = @_;
    return 1 if defined $a && defined $b && $a eq $b;
    return 1 if !defined $a && !defined $b;
    return 0;
}

1;
