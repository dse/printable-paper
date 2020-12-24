package My::Printable::Paper::2::InkscapeShell;
use warnings;
use strict;
use v5.10.0;

use Moo;

use String::ShellQuote qw(shell_quote);
use Expect qw();

has 'hasNewShellStyle' => (is => 'rw', default => 0);

has expect => (
    is => 'rw', lazy => 1, builder => sub {
        my $self = shift;
        my @cmd = ('inkscape', '--shell', '--without-gui');
        my $expect = Expect->new();
        $expect->raw_pty(0);
        $expect->spawn(@cmd) or die("Cannot spawn @cmd: $!\n");
        $expect->expect(60, [
            qr{> action1:arg1;(.|\r|\n)*>}s => sub {
                my $expect = shift;
                $self->hasNewShellStyle(1);
            }
        ], [
            qr{>}s => sub {
                my $expect = shift;
                $self->hasNewShellStyle(0);
            }
        ]);
        return $expect;
    },
);
has verbose => (is => 'rw', default => 0);

sub cmd {
    my ($self, $cmd) = @_;
    $cmd =~ s{\R\z}{};          # safer chomp
    if ($self->verbose) {
        printf STDERR ("Running $cmd in Inkscape shell.\n");
    }
    $self->expect->send("$cmd\n");
    $self->expect->expect(60, ">");
    print "\n";
}

sub export {
    my ($self, $from, $to) = @_;
    if ($self->hasNewShellStyle) {
        my $cmd = sprintf('%s export-filename:%s; export-dpi:600; export-do',
                          $from,
                          $to);
        $self->cmd($cmd);
    } else {
        my $cmd = sprintf('%s --export-dpi=600 --export-file=%s',
                          shell_quote($from),
                          shell_quote($to));
        $self->cmd($cmd);
    }
}

1;
